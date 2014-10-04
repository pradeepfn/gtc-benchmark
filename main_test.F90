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

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                            !
!                 Gyrokinetic Toroidal Code (GTC)                            !
!                          Version 2                                         !
!          Zhihong Lin, Stephane Ethier, Jerome Lewandowski                  !
!              Princeton Plasma Physics Laboratory                           !
!                                                                            !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

program gtc
  use global_parameters
  use particle_array
  use particle_tracking
  use field_array
  use diagnosis_array
  implicit none

  integer i,ierror,m
  real(wp) :: avg_weight,avg_abs_weight
  real(doubleprec) time(8),timewc(8),t0,dt,t0wc,dtwc,loop_time
  real(doubleprec) tracktcpu,tracktwc,tr0,tr0wc
  character(len=10) ic(8)

! MPI initialize
  call mpi_init(ierror)

! input parameters, setup equilibrium, allocate memory 
  CALL SETUP

! initialize particle position and velocity
  CALL LOAD

  avg_weight=0.0_wp
  do m=1,mi
     avg_weight=avg_weight+zion(5,m)
     avg_abs_weight=avg_abs_weight+abs(zion(5,m))
  enddo
  avg_weight=avg_weight/real(mi)
  avg_abs_weight=avg_abs_weight/real(mi)

  write(0,*)mype,'  avg_weight =',avg_weight,'   avg_abs_weight =',avg_abs_weight

! MPI finalize
  call mpi_finalize(ierror)

end program gtc

!=========================================
subroutine timer(t0,dt,t0wc,dtwc)
!=========================================
  use precision
  implicit none
  real(doubleprec) t0,dt,t0wc,dtwc
  real(doubleprec) t1,t1wc

! Get cpu usage time since the beginning of the run and subtract value
! from the previous call
  call cpu_time(t1)
  dt=t1-t0
  t0=t1

! Get wall clock time and subtract value from the previous call
  t1wc=MPI_WTIME()
  dtwc=t1wc-t0wc
  t0wc=t1wc

end subroutine timer

