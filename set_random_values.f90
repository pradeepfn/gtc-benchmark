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

module rng_gtc
  use rng
! Declarations and parameters for the portable random number generator
  integer,dimension(rng_s) :: seed
  type(rng_state) :: state
end module rng_gtc

subroutine rand_num_gen_init
  use global_parameters
  use rng_gtc
  implicit none

  integer i,m,nsize
  integer,dimension(:),allocatable :: mget,mput

  if(rng_control==0)then
   ! **** Use the intrinsic F90 random number generator *****
   ! initialize f90 random number generator
     call random_seed
     call random_seed(size=nsize)
     allocate(mget(nsize),mput(nsize))
     call random_seed(get=mget)
     if(mype==0) then
        if(stdout /= 6 .and. stdout /= 0)open(stdout,file='stdout.out',status='old',position='append')
        write(stdout,*)"random_seed=",nsize,mget
        if(stdout /= 6 .and. stdout /= 0)close(stdout)
     end if
     do i=1,nsize 
        call system_clock(m)   !random initialization for collision
        if(irun==0)m=1         !same initialization
        mput(i)=111111*(mype+1)+m+mget(i)
     enddo
     call random_seed(put=mput)
     deallocate(mget,mput)

  ! ****** Use Charles Karney's portable random number generator *****
  elseif(rng_control>0)then
   ! All the processors start with the same seed.
     call rng_set_seed(seed,(rng_control-1))  !Set seed to (rng_control-1)
     if(mype==0)write(0,*)'Seed is set to ',rng_print_seed(seed)
   ! Initialize the random number generator
     call rng_init(seed,state)

  else
   ! Set seed to current time
     call rng_set_seed(seed)
   ! Advance seed according to process number
     call rng_step_seed(seed,mype)
   ! Initialize random number generator
     call rng_init(seed,state)
  endif

end subroutine rand_num_gen_init

subroutine set_random_zion
  use global_parameters
  use particle_array
  use rng_gtc
  implicit none

  integer :: i,ierr

  if(rng_control==0)then
   ! Use Fortran's intrinsic random number generator
     call random_number(zion(2,1:mi))
     call random_number(zion(3,1:mi))
     call random_number(zion(4,1:mi))
     call random_number(zion(5,1:mi))
     call random_number(zion(6,1:mi))

  elseif(rng_control>0)then
   ! The following calls to rng_number insure that the series of random
   ! numbers generated will be the same for a given seed no matter how
   ! many processors are used. This is useful to test the reproducibility
   ! of the results on different platforms and for general testing.
     do i=1,mype+1
        call rng_number(state,zion(2:6,1:mi))
     enddo
   ! We now force the processes to wait for each other since the preceding
   ! loop will take an increasing amount of time 
     call MPI_BARRIER(MPI_COMM_WORLD,ierr)

  else
     call rng_number(state,zion(2,1:mi))
     call rng_number(state,zion(3,1:mi))
     call rng_number(state,zion(4,1:mi))
     call rng_number(state,zion(5,1:mi))
     call rng_number(state,zion(6,1:mi))
  endif

! Debug statements
!  do i=1,mi
!     write(mype+50,*)(i+mi*mype),zion(2:6,i)
!  enddo
!  close(mype+50)

end subroutine set_random_zion
