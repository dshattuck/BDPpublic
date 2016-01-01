/*
 * 
 * BDP BrainSuite Diffusion Pipeline
 * 
 * Copyright (C) 2015 The Regents of the University of California and
 * the University of Southern California
 * 
 * Created by Chitresh Bhushan, Justin P. Haldar, Anand A. Joshi, David W. Shattuck, and Richard M. Leahy
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


/*   undef needed for LCC compiler
 *
 * Original license below: 
 * http://www.mathworks.com/matlabcentral/fileexchange/21451-multimodality-non-rigid-demon-algorithm-image-registration
 * 
 * Copyright (c) 2009, Dirk-Jan Kroon
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in
 *   the documentation and/or other materials provided with the distribution
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

#undef EXTERN_C
#ifdef _WIN32
#include <windows.h>
#include <process.h>
#define voidthread unsigned __stdcall
#define EndThread _endthreadex(0); return 0
#define ThreadHANDLE HANDLE
#define WaitForThreadFinish(t) WaitForSingleObject(t, INFINITE);CloseHandle(t)
#define StartThread(a,b,c) a=(HANDLE)_beginthreadex(NULL, 0, b, c, 0, NULL );
#else
#include <pthread.h>
#define voidthread void
#define EndThread pthread_exit(NULL)
#define ThreadHANDLE pthread_t
#define WaitForThreadFinish(t) pthread_join(t, NULL)
#define StartThread(a,b,c) pthread_create((pthread_t*)&a, NULL, (void*)b, c);
#endif
