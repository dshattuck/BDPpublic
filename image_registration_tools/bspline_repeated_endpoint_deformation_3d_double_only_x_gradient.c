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
#include "multiple_os_thread.h"

/* Same as bspline_repeated_endpoint_deformation_3d_double_only_x(), except that this function also 
 * calculates dB_prod term for gradient computation. This function can be probably faster when 
 * several b-spline coefficients are zero. Usage: 
 * [tx,dtx] = bspline_repeated_endpoint_deformation_3d_double_only_x_gradient(Ox, sz, spacing, nThreads);
 * 
 * Ox is 3D-grid of control-points  (NO end-point repeatation). Ox should parameterize 
 *       the deformation-field (& NOT the Map!). See bspline_grid_generate_deformation.m
 *
 * Copyright (c) 2013, C. Bhushan, USC
 */

static __inline int mindex2(int x, int y, int sizx) { return y*sizx+x; }

voidthread computeDeformation(double **Args) {
   double *Bu, *Bv, *Bw, *Tx, *dBu, *dTx;
   double *dxa, *dya, *dza, *ThreadID, *Ox;
   double *Isize_d;
   double *Osize_d;
   double *nlhs_d;
   int Isize[3]={0,0,0};
   int Osize[3]={0,0,0};
   double *Nthreadsd;
   int Nthreads;
   int ThreadOffset; /* starting index for Multiple threads */
   double Tlocalx, dTlocalx; /* current pixel maps to Tlocalx */
   
   /* Variables to store 1D index */
   int indexO;
   int indexI;
   
   int dx,dy,dz; /* Grid distance */
   int x,y,z;    /* X,Y,Z coordinates of current pixel */
   
   /* B-spline variables */
   int u_index=0, v_index=0, w_index=0;
   int Ox_Index, Oy_Index, Oz_Index;
   int Bu_Index, Bv_Index, Bw_Index;
   int i, j, k;   
   double temp_prod; /* temporary value */
   
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
   dxa=Args[7];
   dya=Args[8];
   dza=Args[9];
   ThreadID=Args[10];
   Ox=Args[11];
   nlhs_d=Args[12];
   dBu=Args[13];
   dTx=Args[14];
   
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
      u_index_array[x]=((x%dx)*4) + 3; /* multiplied by 4, as it is loc of 2nd dim in Bu */
                                       /* i.e. in matlab notation, location of Bu(1, (x%dx)).*/
                                       /* +3 to point to index 0:3 (in matrix Bu), corresponding to 
                                        * (-3:0)th control point for current segment. */

      i_array[x]=(int)floor((double)x/dx) + 2; /* Segment number corresponding to the current pixel. */
                                               /* For s-th segment, non-zero splines are those 
                                                * corresponding to control-point numbers 
                                                * (s-3), (s-2), (s-1), and s. 
                                                * Control point numbering starts from zero. 
                                                * Segment corresponding to 1st voxel (x=0) would 
                                                * be 2 for uniform cubic b-splines. */
   }
   for (y=0; y<Isize[1]; y++) {
      v_index_array[y]=((y%dy)*4) + 3;
      j_array[y]=(int)floor((double)y/dy) + 2;
   }
   for (z=ThreadOffset; z<Isize[2]; z++) {
      w_index_array[z]=((z%dz)*4) + 3;
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
            Tlocalx=0;
            dTlocalx=0;
            
            for(l=-3; l<=0; l++) { /* index of b-spline segment, -3 to 0 */
               Ox_Index = i+l;
               Bu_Index = u_index+l;
               
               /* Repeat control points on end-points */
               if(Ox_Index<0) { Ox_Index = 0; }
               else if(Ox_Index>=Osize[0]) { Ox_Index = Osize[0]-1; }
               
               for(m=-3; m<=0; m++) {
                  Oy_Index = j+m;
                  Bv_Index = v_index+m;
                  if(Oy_Index<0) { Oy_Index = 0; }
                  else if(Oy_Index>=Osize[1]) { Oy_Index = Osize[1]-1; }
                  
                  for(n=-3; n<=0; n++) {
                     Oz_Index = k+n;
                     Bw_Index = w_index+n;
                     if(Oz_Index<0) { Oz_Index = 0; }
                     else if(Oz_Index>=Osize[2]) { Oz_Index = Osize[2]-1; }
                     
                     indexO = (Ox_Index) + (Oy_Index)*Osize[0] + (Oz_Index)*Osize[0]*Osize[1];
                     if(fabs(Ox[indexO])>1e-10) {
                        temp_prod = Bv[Bv_Index]*Bw[Bw_Index]*Ox[indexO];
                        Tlocalx+=(Bu[Bu_Index]*temp_prod);
                        dTlocalx+=(dBu[Bu_Index]*temp_prod);
                     }
                  }
               }
            }
            
            indexI = x+y*Isize[0]+z*Isize[0]*Isize[1]; /* current pixel address */
            Tx[indexI] = Tlocalx;                      /* deformation in current pixel */
            dTx[indexI] = dTlocalx;
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

   double *Ox,*Isize, *spacing, *Nthreadsd; /* Inputs */
   double *Tx, *dTx; /* outputs */
   
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
   double *Bu, *Bv, *Bw, *dBu;
   int dx,dy,dz;
   
   int i,x,y,z;  /* Loop variable  */

   /* Check for proper number of arguments. */
   if(nrhs!=4) {
      mexErrMsgTxt("Exactly four inputs are required.");
   }
   
   if(nlhs>2) {
      mexErrMsgTxt("Exactly two output variable required.");
   }
   
   /* Get the sizes of the grid */
   dims = mxGetDimensions(prhs[0]);
   Osizex = dims[0];
   Osizey = dims[1];
   Osizez = dims[2];

   /* Assign pointers to each input. */
   Ox=(double *)mxGetData(prhs[0]);
   Isize=(double *)mxGetData(prhs[1]);
   spacing=(double *)mxGetData(prhs[2]);
   Nthreadsd=(double *)mxGetData(prhs[3]);
   
   Idims[0] = (mwSize)Isize[0];
   Idims[1] = (mwSize)Isize[1];
   Idims[2] = (mwSize)Isize[2];   
   plhs[0] = mxCreateNumericArray(3, Idims, mxDOUBLE_CLASS, mxREAL);
   plhs[1] = mxCreateNumericArray(3, Idims, mxDOUBLE_CLASS, mxREAL);

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
   dTx=(double *)mxGetData(plhs[1]);
   
   /*  Make polynomial look up tables   */
   Bu=malloc(dx*4*sizeof(double));  /* 4 x dx size array */
   Bv=malloc(dy*4*sizeof(double));
   Bw=malloc(dz*4*sizeof(double));
   dBu=malloc(dx*4*sizeof(double));
   for (x=0; x<dx; x++) {
      u=((double)x/(double)dx)-floor((double)x/(double)dx);
      Bu[mindex2(0,x,4)] = (double)pow((1-u),3)/6;  /* corresponding to segment -3 in spline book */
      Bu[mindex2(1,x,4)] = (double)( 3*pow(u,3) - 6*pow(u,2) + 4)/6;
      Bu[mindex2(2,x,4)] = (double)(-3*pow(u,3) + 3*pow(u,2) + 3*u + 1)/6;
      Bu[mindex2(3,x,4)] = (double)pow(u,3)/6;   /* corresponding to segment -0 in spline book */
      
      /* dBu */
      dBu[mindex2(0,x,4)] = (double)(-1*pow((1-u),2))/2;  /* corresponding to segment -3 in spline book */
      dBu[mindex2(1,x,4)] = (double)( 3*pow(u,2) - 4*u)/2;
      dBu[mindex2(2,x,4)] = (double)(-3*pow(u,2) + 2*u + 1)/2;
      dBu[mindex2(3,x,4)] = (double)pow(u,2)/2;   /* corresponding to segment -0 in spline book */
   }
   
   for (y=0; y<dy; y++) {
      v=((double)y/(double)dy)-floor((double)y/(double)dy);
      Bv[mindex2(0,y,4)] = (double)pow((1-v),3)/6;
      Bv[mindex2(1,y,4)] = (double)( 3*pow(v,3) - 6*pow(v,2) + 4)/6;
      Bv[mindex2(2,y,4)] = (double)(-3*pow(v,3) + 3*pow(v,2) + 3*v + 1)/6;
      Bv[mindex2(3,y,4)] = (double)pow(v,3)/6;
   }

   for (z=0; z<dz; z++) {
      w=((double)z/(double)dz)-floor((double)z/(double)dz);
      Bw[mindex2(0,z,4)] = (double)pow((1-w),3)/6;
      Bw[mindex2(1,z,4)] = (double)( 3*pow(w,3) - 6*pow(w,2) + 4)/6;
      Bw[mindex2(2,z,4)] = (double)(-3*pow(w,3) + 3*pow(w,2) + 3*w + 1)/6;
      Bw[mindex2(3,z,4)] = (double)pow(w,3)/6;
   }
   
   Osize_d[0]=(double)Osizex;  Osize_d[1]=(double)Osizey; Osize_d[2]=(double)Osizez;
   nlhs_d[0]=(double)nlhs;
   
   /* Reserve room for 16 function variables(arrays)   */
   for (i=0; i<Nthreads; i++) {
      
      /*  Make Thread ID  */
      ThreadID1= (double *)malloc( 1* sizeof(double) );
      ThreadID1[0]=(double)i;
      ThreadID[i]=ThreadID1;
      
      /*  Make Thread Structure  */
      ThreadArgs1 = (double **)malloc( 15* sizeof( double * ) );
      ThreadArgs1[0]=Bu;
      ThreadArgs1[1]=Bv;
      ThreadArgs1[2]=Bw;
      ThreadArgs1[3]=Isize;
      ThreadArgs1[4]=Osize_d;      
      ThreadArgs1[5]=Nthreadsd;
      ThreadArgs1[6]=Tx;
      ThreadArgs1[7]=dxa;
      ThreadArgs1[8]=dya;
      ThreadArgs1[9]=dza;
      ThreadArgs1[10]=ThreadID[i];
      ThreadArgs1[11]=Ox;
      ThreadArgs1[12]=nlhs_d;
      ThreadArgs1[13]=dBu;
      ThreadArgs1[14]=dTx;
      
      ThreadArgs[i]=ThreadArgs1;
      StartThread(ThreadList[i], &computeDeformation, ThreadArgs[i])
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


