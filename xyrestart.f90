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

program xyrestart
implicit none
integer:: ihistory,j,mquantity
ihistory
    open(777,file='history_restart.out',status='unknown')
     rewind(ihistory)
   !!!  read(ihistory,101)j
   !!!  write(777,101)j
   !!!  read(ihistory,101)mquantity
   !!!  write(777,101)mquantity
   !!!  read(ihistory,101)mflx
   !!!  write(777,101)mflx
   !!!  read(ihistory,101)n_mode
   !!!  write(777,101)n_mode
   !!!  read(ihistory,101)mstepfinal
   !!!  noutputs=mstepfinal-mstep/ndiag+istep/ndiag
   !!!  write(777,101)noutputs
   !!!  do i=0,(mquantity+mflx+4*n_mode)*noutputs
   !!!     read(ihistory,102)dum
   !!!     write(777,102)dum
   !!!  enddo
   !!!  close(777)

   ! Now do sheareb.out
   !!!  open(777,file='sheareb_restart.out',status='unknown')
   !!!  rewind(444)
   !!!  read(444,101)j
   !!!  write(777,101)j
   !!!  do i=1,mpsi*noutputs
   !!!     read(444,102)dum
   !!!     write(777,102)dum
   !!!   enddo
   !!!  close(777)
!  endif

101 format(i6)
102 format(e12.6)
