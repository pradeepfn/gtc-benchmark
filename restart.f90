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

subroutine restart_write
  use global_parameters
  use particle_array
  use field_array
  use diagnosis_array
  implicit none

  interface
     function fsync (fd) bind(c,name="fsync")
     use iso_c_binding, only: c_int
     integer(c_int), value :: fd
     integer(c_int) :: fsync
     end function fsync
  end interface

  character(len=18) cdum
  character(len=10) restart_dir
  character(len=60) file_name
  real(wp) dum
  integer i,j,mquantity,mflx,n_mode,mstepfinal,noutputs,notify
  integer save_restart_files,ierr,ret

  !save_restart_files=1
  save_restart_files=0

!!!!!!!!!!!!!!!******************
!!  if(mype < 10)then
!!     write(cdum,'("DATA_RESTART.00",i1)')mype
!!   elseif(mype < 100)then
!!     write(cdum,'("DATA_RESTART.0",i2)')mype
!!  else
!!     write(cdum,'("DATA_RESTART.",i3)')mype
!!  endif
!!!!!!!!!!!!!************************

  if(mype < 10)then
     write(cdum,'("DATA_RESTART.0000",i1)')mype
  elseif(mype < 100)then
     write(cdum,'("DATA_RESTART.000",i2)')mype
  elseif(mype < 1000)then
     write(cdum,'("DATA_RESTART.00",i3)')mype
  elseif(mype < 10000)then
     write(cdum,'("DATA_RESTART.0",i4)')mype
  else
     write(cdum,'("DATA_RESTART.",i5)')mype
  endif 


  if(save_restart_files==1)then
     write(restart_dir,'("STEP_",i0)')(mstepall+istep)
     if(mype==0)call system("mkdir "//restart_dir)
     call MPI_BARRIER(MPI_COMM_WORLD,ierr)
     file_name=trim(restart_dir)//'/'//trim(cdum)
     open(222,file=file_name,status='replace',form='unformatted')
  else
     call MPI_BARRIER(MPI_COMM_WORLD,ierr)
     open(222,file=cdum,status='replace',form='unformatted')
  endif
#ifdef _NVRAM_RESTART
! record particle information for future restart run
  write(222)istep+mstepall,mi,me,ntracer
  if(mype==0)write(222)etracer,ptracer

  call chkpt_all(mype);
#else
  write(222)istep+mstepall,mi,me,ntracer,rdtemi,rdteme,pfluxpsi,phi,phip00,zonali,zonale
  if(mype==0)write(222)etracer,ptracer
  write(222)zion(1:nparam,1:mi),zion0(6,1:mi)
  if(nhybrid>0)write(222)phisave,zelectron(1:6,1:me),zelectron0(6,1:me)
#endif
!_NVRAM

  flush(222)
  ret = fsync(fnum(222))
  if (ret /= 0) stop "Error calling FSYNC"
  close(222)

#ifdef DEBUG
  print *, "mi, me , ntracer, etracer, ptracer ", mi, me, ntracer,istep, etracer, ptracer
  print *, "checkpointed zonali value : ", zonali
  print *, "checkpointed zonale value : ", zonale
  print *, "checkpointed phip00 value : ", phip00
  print *, "###################checkpointed process id : ", mype
#endif
!DEBUG
! S.Ethier 01/30/04 Save a copy of history.out and sheareb.out for restart
  if(mype==0 .and. istep<=mstep)then
     open(777,file='history_restart.out',status='replace')
     rewind(ihistory)
     read(ihistory,101)j
     write(777,101)j
     read(ihistory,101)mquantity
     write(777,101)mquantity
     read(ihistory,101)mflx
     write(777,101)mflx
     read(ihistory,101)n_mode
     write(777,101)n_mode
     read(ihistory,101)mstepfinal
     noutputs=mstepfinal-mstep/ndiag+istep/ndiag
     write(777,101)noutputs
     do i=0,(mquantity+mflx+4*n_mode)*noutputs
        read(ihistory,102)dum
        write(777,102)dum
     enddo
     close(777)

    endif

!we are introducing a barrier and file write to avoid data corruption
call MPI_BARRIER(MPI_COMM_WORLD,ierr)
if(mype==0)then
   open(456,file='notify/gtc.notify',status='old')
   read(456,101)notify
   if(notify==1)then
     write(stdout,*)'preparing to terminate...'
     close(456)
     call EXIT(1)
   endif
  close(456)
endif

101 format(i6)
102 format(e12.6)

end subroutine restart_write

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine restart_read
  use global_parameters
  use particle_array
  use field_array
  use diagnosis_array
  implicit none

  integer m
  character(len=18) cdum


!!!!********************************************
  
!!  if(mype < 10)then
!!     write(cdum,'("DATA_RESTART.00",i1)')mype
!!  elseif(mype < 100)then
!!     write(cdum,'("DATA_RESTART.0",i2)')mype
!!  else
!!     write(cdum,'("DATA_RESTART.",i3)')mype
!!  endif


!!!!!!!****************************************

  if(mype < 10)then
     write(cdum,'("DATA_RESTART.0000",i1)')mype
  elseif(mype < 100)then
     write(cdum,'("DATA_RESTART.000",i2)')mype
  elseif(mype < 1000)then
     write(cdum,'("DATA_RESTART.00",i3)')mype
  elseif(mype < 10000)then
     write(cdum,'("DATA_RESTART.0",i4)')mype
  else
     write(cdum,'("DATA_RESTART.",i5)')mype
  endif



  open(333,file=cdum,status='old',form='unformatted')

! read particle information to restart previous run
#ifdef _NVRAM_RESTART
  read(333)restart_step,mi,me,ntracer
  if(mype==0)read(333)etracer,ptracer
#else
  read(333)restart_step,mi,me,ntracer,rdtemi,rdteme,pfluxpsi,phi,phip00,zonali,zonale
  if(mype==0)read(333)etracer,ptracer
  read(333)zion(1:nparam,1:mi),zion0(6,1:mi)
  if(nhybrid>0)read(333)phisave,zelectron(1:6,1:me),zelectron0(6,1:me)
#endif
  close(333)

#ifdef DEBUG
  print *, "restart values mi,me,ntracer,restart_step,etracer,ptracer : ",mi,me,ntracer,restart_step,etracer,ptracer
  print *, "zonali value in fortran restart procedure : ",zonali
  print *, "zonale value in fortran restart procedure : ",zonale
  print *, "phip00 value in fortran restart proceduere : ",phip00
#endif
  return

! test domain decomposition
  do m=1,mi
     if(zion(3,m)>zetamax+1.0e-10 .or. zion(3,m)<zetamin-1.0e-10)then
        print *, 'PE=',mype, ' m=',m, ' zion=',zion(3,m)
        stop
     endif
  enddo
  if(nhybrid>0)then
     do m=1,me
        if(zelectron(3,m)>zetamax+1.0e-10 .or. zelectron(3,m)<zetamin-1.0e-10)then
           print *, 'PE=',mype, ' m=',m, ' zelectron=',zelectron(3,m)
           stop
        endif
     enddo
  endif

end subroutine restart_read

subroutine resume_step
  use global_parameters
  use particle_array
  use field_array
  use diagnosis_array
  implicit none

  integer i,j
  character(len=18) fname

  if(mype < 10)then
     write(fname,'("DATA_RESTART.0000",i1)')mype
  elseif(mype < 100)then
     write(fname,'("DATA_RESTART.000",i2)')mype
  elseif(mype < 1000)then
     write(fname,'("DATA_RESTART.00",i3)')mype
  elseif(mype < 10000)then
     write(fname,'("DATA_RESTART.0",i4)')mype
  else
     write(fname,'("DATA_RESTART.",i5)')mype
  endif

  open(333,file=fname,status='old',form='unformatted')
  ! reading the last step 
  read(333)restart_step
  close(333)
end subroutine
