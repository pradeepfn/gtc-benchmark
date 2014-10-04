! Copyright 2008 Z. Lin <zhihongl@uci.edu>
!
! This file is part of GTC version 1.
!
! GTC version 1 is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! GTC version 1 is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with GTC version 1.  If not, see <http://www.gnu.org/licenses/>.

!"fft_sx6.f90": 1D FFT
! Same as CRAY fft routines except for the dimensions of the work arrays
subroutine fftr1d(isign,irank,scale,x,y,icount)

  integer initial(3),isign,irank,icount
  real,dimension(:),allocatable :: table1,table2,table3
  real x(irank),scale,work(6*irank)
  complex y(irank/2+1)

  save initial,table1,table2,table3

  if(icount==1)then
! initialize cray-t3e fft
     if(initial(icount)/=1)then
        initial(icount)=1
        allocate(table1(2*irank))
        call scfft(0,irank,scale,x,y,table1,work,0)
     endif
! forward and backward 1d real fft
     if(isign==1)then
        call scfft(1,irank,scale,x,y,table1,work,0)
     else
        call csfft(-1,irank,scale,y,x,table1,work,0)
     endif

  elseif(icount==2)then
     if(initial(icount)/=1)then
        initial(icount)=1
        allocate(table2(2*irank))
        call scfft(0,irank,scale,x,y,table2,work,0)
     endif
     if(isign==1)then
        call scfft(1,irank,scale,x,y,table2,work,0)
     else
        call csfft(-1,irank,scale,y,x,table2,work,0)
     endif

  elseif(icount==3)then
     if(initial(icount)/=1)then
        initial(icount)=1
        allocate(table3(2*irank))
        call scfft(0,irank,scale,x,y,table3,work,0)
     endif
     
     if(isign==1)then
        call scfft(1,irank,scale,x,y,table3,work,0)
     else
        call csfft(-1,irank,scale,y,x,table3,work,0)
     endif
  endif
  
end subroutine fftr1d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine fftc1d(isign,irank,scale,x)
  
  integer initial,isign,irank
  real,dimension(:),allocatable :: table
  real scale,work(4*irank)
  complex x(irank)

  save initial,table

  if(initial/=1)then
     initial=1
     allocate(table(2*irank))
     call ccfft(0,irank,scale,x,x,table,work,0)
  endif

  call ccfft(isign,irank,scale,x,x,table,work,0)

end subroutine fftc1d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
