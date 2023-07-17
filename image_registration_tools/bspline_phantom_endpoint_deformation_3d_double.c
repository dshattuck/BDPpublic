/*
 * 
 * BDP BrainSuite Diffusion Pipeline
 * 
 * Copyright (C) 2023 The Regents of the University of California and
 * the University of Southern California
 * 
 * Created by Chitresh Bhushan, Divya Varadarajan, Justin P. Haldar, Anand A. Joshi,
 *            David W. Shattuck, and Richard M. Leahy
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
 * USA.
 * 
 */


#include "mex.h"
#include "math.h"
#include "image_interpolation.h"
#include "multiple_os_thread.h"

/* Modified from bspline_deformation_3d_double.c to use uniform-cubic bspline
 * with phantom end control points (which are knot points as well). It just
 * return the deformation after fitting the cubic bspline. 
 *
 * The input control points should have the phantom end points. This function
 * assumes the phantom are included in input and should be generally called from the
 * matlab function bspline_phantom_endpoint_deformation.m
 */


/* 3D Bspline transformation grid function
 * function [Tx,Ty,Tz] = bspline_phantom_endpoint_deformation_3d_double(Ox, Oy, Oz, size(Vin), spacing, nthreads)
 *
 * Ox, Oy, Oz are the grid points coordinates (Phantom points should be present)
 * size(Vin) is size of input image (dimension should be multiple of spacing)
 * spacing - spacing of the b-spline knots
 * nthreads - no of threads to use
 *
 * Tx: The transformation field in x direction
 * Ty: The transformation field in y direction
 * Tz: The transformation field in y direction
 *
 * This function is a modified implementation of the b-spline registration
 * algorithm in "D. Rueckert et al. : Nonrigid Registration Using Free-Form
 * Deformations: Application to Breast MR Images".
 *
 * We used "Fumihiko Ino et al. : a data distrubted parallel algortihm for
 * nonrigid image registration" for the correct formula's, because
 * (most) other papers contain errors.
 *
 * Copyright (c) 2013, C. Bhushan, USC
 *
 * This code is modified from bspline_deformation_3d_double.c release under 
 * BSD license at: 
 * http://www.mathworks.com/matlabcentral/fileexchange/20057-b-spline-grid--image-and-point-based-registration
 *
 * Copyright (c) 2009, Dirk-Jan Kroon
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the distribution
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

voidthread transformvolume(double **Args) {
   double *Bu, *Bv, *Bw, *Tx, *Ty, *Tz;
   double *dxa, *dya, *dza, *ThreadID, *Ox, *Oy, *Oz;
   double *Isize_d;
   double *Osize_d;
   double *nlhs_d;
   int Isize[3]={0,0,0};
   int Osize[3]={0,0,0};
   double *Nthreadsd;
   int Nthreads;
   /* Multiple threads, one does the odd the other even indexes */
   int ThreadOffset;
   /* Location of pixel which will be come the current pixel */
   double Tlocalx;
   double Tlocaly;
   double Tlocalz;
   /* Cubic and outside black booleans */
   bool black, cubic;
   /* Variables to store 1D index */
   int indexO;
   int indexI;
   /* Grid distance */
   int dx,dy,dz;
   /* X,Y,Z coordinates of current pixel */
   int x,y,z;
   /* B-spline variables */
   int u_index=0, v_index=0, w_index=0;
   int Ox_Index, Oy_Index, Oz_Index;
   int Bu_Index, Bv_Index, Bw_Index;
   int i, j, k;
   /* temporary value */
   double val;
   /* Look up tables index */
   int *u_index_array, *i_array;
   int *v_index_array, *j_array;
   int *w_index_array, *k_array;
   /*  B-Spline loop variabels */
   int l,m,n;
   int nlhs=0;
   /* Split input into variables */
   Bu=Args[0];
   Bv=Args[1];
   Bw=Args[2];
   Isize_d=Args[3];
   Osize_d=Args[4];
   Nthreadsd=Args[5];
   Tx=Args[6];
   Ty=Args[7];
   Tz=Args[8];
   dxa=Args[9];
   dya=Args[10];
   dza=Args[11];
   ThreadID=Args[12];
   Ox=Args[13];
   Oy=Args[14];
   Oz=Args[15];
   nlhs_d=Args[16];
   
   Nthreads=(int)Nthreadsd[0];
   
   nlhs=(int)nlhs_d[0];
   Isize[0] = (int)Isize_d[0];
   Isize[1] = (int)Isize_d[1];
   Isize[2] = (int)Isize_d[2];
   Osize[0] = (int)Osize_d[0];
   Osize[1] = (int)Osize_d[1];
   Osize[2] = (int)Osize_d[2];
   
   /* Get the spacing of the uniform b-spline grid */
   dx=(int)dxa[0]; dy=(int)dya[0]; dz=(int)dza[0];
   
   ThreadOffset=(int) ThreadID[0];
   
   /*  Calculate the indexs need to look up the B-spline values. */
   u_index_array= (int*)malloc(Isize[0]* sizeof(int));
   i_array= (int*)malloc(Isize[0]* sizeof(int));
   v_index_array= (int*)malloc(Isize[1]* sizeof(int));
   j_array= (int*)malloc(Isize[1]* sizeof(int));
   w_index_array= (int*)malloc(Isize[2]* sizeof(int));
   k_array= (int*)malloc(Isize[2]* sizeof(int));
   
   for (x=0; x<Isize[0]; x++) {
      u_index_array[x]=(x%dx)*4; /* Already multiplied by 4, because it specifies the y or 2nd dimension */
      i_array[x]=(int)floor((double)x/dx) + 2; /* curve segment number */
   }
   for (y=0; y<Isize[1]; y++) {
      v_index_array[y]=(y%dy)*4;
      j_array[y]=(int)floor((double)y/dy) + 2;
   }
   for (z=ThreadOffset; z<Isize[2]; z++) {
      w_index_array[z]=(z%dz)*4;
      k_array[z]=(int)floor((double)z/dz) + 2;
   }
   
   /*  Loop through all image pixel coordinates */
   for (z=ThreadOffset; z<Isize[2]; z=z+Nthreads) {
      w_index=w_index_array[z];
      k=k_array[z];
      
      for (y=0; y<Isize[1]; y++) {
         v_index=v_index_array[y];
         j=j_array[y];
         
         for (x=0; x<Isize[0]; x++) {
            u_index=u_index_array[x];
            i=i_array[x];
            Tlocalx=0; Tlocaly=0; Tlocalz=0;
            
            for(l=-3; l<=0; l++) {
               Ox_Index = i+l+1;
               Bu_Index = l+u_index+3;
               
               for(m=-3; m<=0; m++) {
                  Oy_Index = j+m+1;
                  Bv_Index = m+v_index+3;
                  
                  for(n=-3; n<=0; n++) {
                     Oz_Index = k+n+1;
                     Bw_Index = n+w_index+3;
                     
                     if(Ox_Index<0) { Ox_Index = 0; }
                     else if(Ox_Index>=Osize[0]) { Ox_Index = Osize[0]-1; }
                     if(Oy_Index<0) { Oy_Index = 0; }
                     else if(Oy_Index>=Osize[1]) { Oy_Index = Osize[1]-1; }
                     if(Oz_Index<0) { Oz_Index = 0; }
                     else if(Oz_Index>=Osize[2]) { Oz_Index = Osize[2]-1; }
                     
                     indexO = (Ox_Index) + (Oy_Index)*Osize[0] + (Oz_Index)*Osize[0]*Osize[1];
                     
                     val = Bu[Bu_Index]*Bv[Bv_Index]*Bw[Bw_Index];
                     Tlocalx+=val*Ox[indexO];
                     Tlocaly+=val*Oy[indexO];
                     Tlocalz+=val*Oz[indexO];
                  }
               }
            }
            
            /* Set the current pixel value */
            indexI = x+y*Isize[0]+z*Isize[0]*Isize[1];

            /*  Store transformation field */
            Tx[indexI] = Tlocalx-(double)x;
            if(nlhs>1) { Ty[indexI]=Tlocaly-(double)y; }
            if(nlhs>2) { Tz[indexI]=Tlocalz-(double)z; }
         }
      }
   }
   
   /* Free memory index look up tables */
   free(u_index_array);
   free(i_array);
   free(v_index_array);
   free(j_array);
   free(w_index_array);
   free(k_array);
   
   /*  explicit end thread, helps to ensure proper recovery of resources allocated for the thread */
   EndThread;
}

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] )  {

   double *Ox,*Oy,*Oz,*Isize, *spacing, *Nthreadsd; /* Inputs */
   double *Tx,*Ty,*Tz; /* outputs */
   
   double dxa[1]={0}, dya[1]={0}, dza[1]={0};
   int Nthreads;
   
   /* double pointer array to store all needed function variables) */
   double ***ThreadArgs, **ThreadArgs1;
   
   /* Handles to the worker threads */
   ThreadHANDLE *ThreadList;
   
   /* ID of Threads */
   double **ThreadID, *ThreadID1;
   
   double nlhs_d[1]={0};
   const mwSize *dims;
   mwSize Idims[3]={0,0,0};
   mwSize  Osizex, Osizey, Osizez;
   double Osize_d[3]={0,0,0};
   
   /* B-spline variablesl */
   double u,v,w;
   double *Bu, *Bv, *Bw;
   int dx,dy,dz;
   
   int i,x,y,z;  /* Loop variable  */

   /* Check for proper number of arguments. */
   if(nrhs!=6) {
      mexErrMsgTxt("Six inputs are required.");
   }

   /* Get the sizes of the grid */
   dims = mxGetDimensions(prhs[0]);
   Osizex = dims[0];
   Osizey = dims[1];
   Osizez = dims[2];


   /* Assign pointers to each input. */
   Ox=(double *)mxGetData(prhs[0]);
   Oy=(double *)mxGetData(prhs[1]);
   Oz=(double *)mxGetData(prhs[2]);
   Isize=(double *)mxGetData(prhs[3]);
   spacing=(double *)mxGetData(prhs[4]);
   Nthreadsd=(double *)mxGetData(prhs[5]);
   
   Idims[0] = (mwSize)Isize[0];
   Idims[1] = (mwSize)Isize[1];
   Idims[2] = (mwSize)Isize[2];
   
   plhs[0] = mxCreateNumericArray(3, Idims, mxDOUBLE_CLASS, mxREAL);
   if(nlhs>1) { plhs[1] = mxCreateNumericArray(3, Idims, mxDOUBLE_CLASS, mxREAL); }
   if(nlhs>2) { plhs[2] = mxCreateNumericArray(3, Idims, mxDOUBLE_CLASS, mxREAL); }

   /* Get the spacing of the uniform b-spline grid */
   dx=(int)spacing[0]; dy=(int)spacing[1]; dz=(int)spacing[2];
   dxa[0] = spacing[0]; dya[0] = spacing[1];  dza[0] = spacing[2];
   
   Nthreads=(int)Nthreadsd[0];
   
   /* Reserve room for handles of threads in ThreadList  */
   ThreadList = (ThreadHANDLE*)malloc(Nthreads* sizeof( ThreadHANDLE ));
   ThreadID = (double **)malloc( Nthreads* sizeof(double *) );
   ThreadArgs = (double ***)malloc( Nthreads* sizeof(double **) );
   
   
   /* Assign pointer to output. */
   Tx =(double *)mxGetData(plhs[0]);
   if(nlhs>1) { Ty =(double *)mxGetData(plhs[1]); }
   if(nlhs>2) { Tz =(double *)mxGetData(plhs[2]); }
   
   /*  Make polynomial look up tables   */
   Bu=malloc(dx*4*sizeof(double));
   Bv=malloc(dy*4*sizeof(double));
   Bw=malloc(dz*4*sizeof(double));
   for (x=0; x<dx; x++)
   {
      u=((double)x/(double)dx)-floor((double)x/(double)dx);
      Bu[mindex2(0,x,4)] = (double)pow((1-u),3)/6;
      Bu[mindex2(1,x,4)] = (double)( 3*pow(u,3) - 6*pow(u,2) + 4)/6;
      Bu[mindex2(2,x,4)] = (double)(-3*pow(u,3) + 3*pow(u,2) + 3*u + 1)/6;
      Bu[mindex2(3,x,4)] = (double)pow(u,3)/6;
   }
   
   for (y=0; y<dy; y++)
   {
      v=((double)y/(double)dy)-floor((double)y/(double)dy);
      Bv[mindex2(0,y,4)] = (double)pow((1-v),3)/6;
      Bv[mindex2(1,y,4)] = (double)( 3*pow(v,3) - 6*pow(v,2) + 4)/6;
      Bv[mindex2(2,y,4)] = (double)(-3*pow(v,3) + 3*pow(v,2) + 3*v + 1)/6;
      Bv[mindex2(3,y,4)] = (double)pow(v,3)/6;
   }
   

   for (z=0; z<dz; z++)
   {
      w=((double)z/(double)dz)-floor((double)z/(double)dz);
      Bw[mindex2(0,z,4)] = (double)pow((1-w),3)/6;
      Bw[mindex2(1,z,4)] = (double)( 3*pow(w,3) - 6*pow(w,2) + 4)/6;
      Bw[mindex2(2,z,4)] = (double)(-3*pow(w,3) + 3*pow(w,2) + 3*w + 1)/6;
      Bw[mindex2(3,z,4)] = (double)pow(w,3)/6;
   }
   
   
   /*Isize_d[0]=(double)Isizex;  Isize_d[1]=(double)Isizey; Isize_d[2]=(double)Isizez;*/
   Osize_d[0]=(double)Osizex;  Osize_d[1]=(double)Osizey; Osize_d[2]=(double)Osizez;
   nlhs_d[0]=(double)nlhs;
   
   /* Reserve room for 16 function variables(arrays)   */
   for (i=0; i<Nthreads; i++) {
      
      /*  Make Thread ID  */
      ThreadID1= (double *)malloc( 1* sizeof(double) );
      ThreadID1[0]=(double)i;
      ThreadID[i]=ThreadID1;
      
      /*  Make Thread Structure  */
      ThreadArgs1 = (double **)malloc( 18* sizeof( double * ) );
      ThreadArgs1[0]=Bu;
      ThreadArgs1[1]=Bv;
      ThreadArgs1[2]=Bw;
      ThreadArgs1[3]=Isize;
      ThreadArgs1[4]=Osize_d;      
      ThreadArgs1[5]=Nthreadsd;
      ThreadArgs1[6]=Tx;
      ThreadArgs1[7]=Ty;
      ThreadArgs1[8]=Tz;
      ThreadArgs1[9]=dxa;
      ThreadArgs1[10]=dya;
      ThreadArgs1[11]=dza;
      ThreadArgs1[12]=ThreadID[i];
      ThreadArgs1[13]=Ox;
      ThreadArgs1[14]=Oy;
      ThreadArgs1[15]=Oz;
      ThreadArgs1[16]=nlhs_d;
      
      ThreadArgs[i]=ThreadArgs1;
      StartThread(ThreadList[i], &transformvolume, ThreadArgs[i])
   }
   
   for (i=0; i<Nthreads; i++) { WaitForThreadFinish(ThreadList[i]); }
   
   
   for (i=0; i<Nthreads; i++)
   {
      free(ThreadArgs[i]);
      free(ThreadID[i]);
   }
   
   free(ThreadArgs);
   free(ThreadID );
   free(ThreadList);
   
   
   free(Bu);
   free(Bv);
   free(Bw);
}


