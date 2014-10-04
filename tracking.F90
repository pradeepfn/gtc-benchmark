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

!========================================

subroutine tag_particles

!========================================

  use global_parameters
  use particle_array
  use particle_tracking
  implicit none
  integer :: i,m,np,npp

! We keep track of the particles by tagging them with a unique number.
! We add an extra element to the particle array, which holds the
! particle tag, i.e. just a number.
! The input parameter "nptrack" is the total number of particles that
! we track.

! We tag each particle with a unique number that will be carried along
! with it as it moves from one processor/domain to another. To facilitate
! the search for the tracked particles, we give the non-tracked particles
! a negative value.
! CAVEAT: We are storing the tag in a floating point array, which means that
!         for a large number of particles, the truncation error associated
!         with the precision may make some particles have the same tag.
!         This is particularly true in single precision where the maximum
!         number of particles that can be distinguished with tags differing
!         by unity is 2**24-1 = 16,777,215 (16.7 million). The most important
!         is to distinguish the tracked particles between them. The other
!         particles just need to have a negative tag. In order to minimize
!         the effect of the precision truncation, we retag the tracked
!         particles with positive numbers starting at 1.
  do m=1,mi
     zion(7,m)=-real(m+mype*mi)
     zion0(7,m)=zion(7,m)
  enddo

! We divide the number of tracked particles equally between all processors
! as much as possible. If nptrack is not a multiple of numberpe, we add
! 1 particle to some of the the processors until we get to nptrack. We also
! start at mi/2 so that the lower numbers fall around r=0.5 (see subroutine 
! load for the initial particle distribution in r).
  npp=nptrack/numberpe
  if(mype < mod(nptrack,numberpe))npp=npp+1

  do i=1,npp
     m=mi/2+(i/2)*(1-2*mod(i,2))
     np=(mype+1)+(i-1)*numberpe
     zion(7,m)=real(np,wp)
     zion0(7,m)=zion(7,m)
  enddo

!  if(mype==0)write(78,*)'np=',np,'  npp=',npp,'  zion(7,mi/2)=',zion(7,mi/2),&
!                        '  zion(7,1)=',zion(7,1)

!  if(mype==0)then
!  ! On the master process (mype=0), we pick "nptrack" particles that will
!  ! be followed at every time step. To facilitate the search of those
!  ! particles among all the others in the zion arrays of each processor,
!  ! we give them a positive number from 1 to nptrack. The particles are
!  ! picked around r=0.5, which is mi/2.
!    do m=(mi-nptrack)/2,(mi+nptrack)/2-1
!       zion(7,m)=-zion(7,m)
!       zion0(7,m)=-zion(7,m)
!    enddo
!  endif

end subroutine tag_particles

!========================================

subroutine locate_tracked_particles

!========================================

  use global_parameters
  use particle_array
  use particle_tracking
  implicit none
  integer :: i,m,npp,iout

! Check if tracked particles are located on this processor. Particles that
! are tracked at every time step have a positive zion(7,m) value. All the
! others have a negative value.
  iout=mod(istep,isnap)
  if(iout==0)iout=isnap
  npp=0
  do m=1,mi
     if(zion(7,m)>0.0)then
       npp=npp+1
       ptracked(1:nparam,npp,iout)=zion(1:nparam,m)
     endif
  enddo
  ntrackp(iout)=npp

end subroutine locate_tracked_particles

!========================================

subroutine write_tracked_particles

!========================================

  use global_parameters
  use particle_tracking
  implicit none
 
  integer :: i,j
  character(len=10) :: cdum

  if(mype < 10)then
     write(cdum,'("TRACKP.00",i1)')mype
  elseif(mype < 100)then
     write(cdum,'("TRACKP.0",i2)')mype
  else
     write(cdum,'("TRACKP.",i3)')mype
  endif

  open(57,file=cdum,status='unknown',position='append')
  write(57,*)istep,isnap,nptrack
  write(57,*)ntrackp
  do i=1,isnap
     do j=1,ntrackp(i)
        write(57,*)ptracked(1:nparam,j,i)
     enddo
  enddo
  close(57)

end subroutine write_tracked_particles

!========================================

subroutine hdf5out_tracked_particles

!========================================
  use global_parameters
#ifdef __HDF5
  use particle_array
  use particle_tracking
  use hdf5
  implicit none

  integer  :: i,j,m,ipp,npp,ntpart(0:numberpe-1)
  real     :: r,q,theta,theta0,zeta,x,y,z

! HDF5 declarations
  integer(HID_T),SAVE :: file_id       ! File identifier
  integer(HID_T) :: dset_id       ! Dataset identifier
  integer(HID_T) :: filespace     ! Dataspace identifier in file
  integer(HID_T) :: memspace      ! Dataspace identifier in memory
  integer(HID_T) :: plist_id      ! Property list identifier
  integer(HID_T) :: grp_id        ! Group identifier
  integer(HID_T) :: time_id       ! Attribute identifier
  integer(HID_T) :: mpsi_id       ! Attribute identifier
  integer(HID_T) :: npe_id        ! Attribute identifier
  integer(HID_T) :: mtheta_id     ! Attribute identifier
  integer(HID_T) :: radial_id     ! Attribute identifier
  integer(HID_T) :: itran_id      ! Attribute identifier
  integer(HID_T) :: aspace_id     ! Attribute Dataspace identifier
  integer(HID_T) :: a1Dspace_id   ! Attribute Dataspace identifier
  integer     :: ierr             ! Return error flag
  integer     :: comm,info
  real        :: curr_time
  character(len=60),SAVE :: fdum
  character(len=60) :: vdum
  integer :: rank
  integer(HSIZE_T), dimension(2) :: count,dimsf
  integer(HSIZE_T), dimension(2) :: offset
  integer(HSIZE_T), dimension(7) :: dimsfi = (/0,0,0,0,0,0,0/)

  comm = MPI_COMM_WORLD
  info = MPI_INFO_NULL


! This routine is called when idiag=0, right after the first Runge-Kutta
! half step in pushi (irk=1). For this reason, we need to use zion0()
! instead of zion(). At this point, the array zion0() holds the particle
! quantities at the end of the previous full step (irk=2). zion0() is
! also used in pushi at irk=1 to do the particle diagnostics, so using
! the same array ensures synchronization between the ouput files.

! Check if tracked particles are located on this processor. Particles that
! are tracked at every time step have a positive zion(7,m) value. All the
! others have a negative value.
! We transform the coordinates of the particle, which are in magnetic
! coordinates (psi,theta,zeta), to X, Y, Z coordinates.
!
!       r=sqrt(2.0*zion(1,m))
!       q=q0+q1*r/a+q2*r*r/(a*a)
!
! REMINDER: The particles are followed in the magnetic coordinate system,
!           NOT in the field-line following coordinate system. The difference
!           is seen in the "theta" coordinate of each particle, which does
!           not involve the zeta coordinate and q value.

  npp=0
  do m=1,mi
     if(zion(7,m)>0.0)then
       npp=npp+1
       r=sqrt(2.0*zion(1,m))
       q=q0+q1*r/a+q2*r*r/(a*a)
       zeta=zion(3,m)
       theta0=zion(2,m)
       x=cos(zeta)*(1.0+r*cos(theta0))
       y=sin(zeta)*(1.0+r*cos(theta0))
       z=r*sin(theta0)
       ptracked(1,npp,1)=x
       ptracked(2,npp,1)=y
       ptracked(3,npp,1)=z
       ptracked(4,npp,1)=zion(4,m)
       ptracked(5,npp,1)=zion(5,m)
       ptracked(6,npp,1)=zion(6,m)
       ptracked(7,npp,1)=zion(7,m)
     endif
  enddo

! Initializes the HDF5 library and the Fortran90 interface
  call h5open_f(ierr)

! We need to know how many tracked particles each process has. This will
! be required to calculate the offset in the HDF5 file.
  ntpart=0
  call MPI_ALLGATHER(npp,1,MPI_INTEGER,ntpart,1,MPI_INTEGER,comm,ierr)

  !if(mype==0)write(78,*)'istep =',istep,'  ntpart =',ntpart

!  if(mod((istep-ndiag),isnap)==0)then
   ! We open a new hdf5 file at the first diagnostic call after an output
   ! to the snapshot files.

  if(track_particles > 0)then
   ! Setup file access property list with parallel I/O access.
     call h5pcreate_f(H5P_FILE_ACCESS_F,plist_id,ierr)
     call h5pset_fapl_mpio_f(plist_id,comm,info,ierr)

   ! Filename for grid quantities
     !!write(fdum,'("TRACKP_",i0,".h5")')(1+(mstepall+istep-ndiag)/isnap)
     write(fdum,'("PARTICLES/TRACKP_",i5.5,".h5")')(mstepall+istep)

   ! Create the file collectively.
     call h5fcreate_f(fdum,H5F_ACC_TRUNC_F,file_id,ierr,access_prp=plist_id)

   ! Close access to a property list
     call h5pclose_f(plist_id,ierr)

  else
   ! Reopen the hdf5 file used during the last call to this subroutine.

   ! Setup file access property list with parallel I/O access.
     call h5pcreate_f(H5P_FILE_ACCESS_F,plist_id,ierr)
     call h5pset_fapl_mpio_f(plist_id,comm,info,ierr)

   ! Reopen the file collectively.
     call h5fopen_f(fdum,H5F_ACC_RDWR_F,file_id,ierr,access_prp=plist_id)

   ! Close access to a property list
     call h5pclose_f(plist_id,ierr)

  endif

! Create the data space for the 2D dataset:
!  1st dim: 7 quantities = particle phase space coordinates + identifier
!  2nd dim: number of tracked particles
  rank=2
  dimsf(1)=nparam
  dimsf(2)=nptrack
  call h5screate_simple_f(rank,dimsf,filespace,ierr)

! Write dataset name into variable
!!  write(vdum,'("Particles_t",i0)')(mstepall+istep)/ndiag
  vdum="particle_data"

! Create the dataset with default properties.
  call h5dcreate_f(file_id,vdum,H5T_NATIVE_REAL,filespace,dset_id,ierr)
  call h5sclose_f(filespace,ierr)

! We now write the current calculation time as an attribute to the
! dataset. We need create the attribute data space, data type, etc.
! Only one processor needs to write the attribute.

!! Create scalar data space for the time attribute that will be attached to
!! the particle dataset.
!  call h5screate_f(H5S_SCALAR_F,aspace_id,ierr)
!
!! Create dataset attribute
!  call h5acreate_f(dset_id,"time",H5T_NATIVE_REAL,aspace_id,time_id,ierr)
!
!  curr_time=real(mstepall+istep)*tstep  ! Attribute data
!
!! Write the time attribute data. Here dimsfi is just a dummy argument.
!  if(mype.eq.0)then
!    call h5awrite_f(time_id,H5T_NATIVE_REAL,curr_time,dimsfi,ierr)
!  endif
!
!! Release attribute id, attribute data space
!  call h5aclose_f(time_id,ierr)
!  call h5sclose_f(aspace_id,ierr)

! Each process defines a dataset in memory and writes it to the hyperslab
! in the file.
! First dimension is the particle quantities.
  count(1)=nparam
  offset(1)=0

! Second dimension is the number of tracked particles.
! The offset is determine by the sum of tracked particles on PEs < mype
  ipp=0
  do i=0,mype-1
     ipp=ipp+ntpart(i)
  enddo
  count(2)=npp
  offset(2)=ipp

  dimsfi(1)=count(1)
  dimsfi(2)=count(2)

! Only the processes holding tracked particles participate in the output
! to the HDF5 file:
  if(npp > 0)then
    call h5screate_simple_f(rank,count,memspace,ierr)

  ! Select hyperslab in the file.
    call h5dget_space_f(dset_id,filespace,ierr)
    call h5sselect_hyperslab_f(filespace,H5S_SELECT_SET_F,offset,count,ierr)
  
  ! Create property list for collective dataset write
    call h5pcreate_f(H5P_DATASET_XFER_F, plist_id, ierr)
  !!!  call h5pset_dxpl_mpio_f(plist_id, H5FD_MPIO_COLLECTIVE_F, ierr)
    call h5pset_dxpl_mpio_f(plist_id, H5FD_MPIO_INDEPENDENT_F, ierr)

  ! Write the dataset
    call h5dwrite_f(dset_id,H5T_NATIVE_REAL,ptracked, dimsfi,ierr, &
         file_space_id=filespace,mem_space_id=memspace,xfer_prp=plist_id)

  ! Close property list and dataspaces.
    call h5pclose_f(plist_id,ierr)
    call h5sclose_f(filespace,ierr)
    call h5sclose_f(memspace,ierr)
  endif

! Close dataset.
  call h5dclose_f(dset_id,ierr)

! Close hdf5 file to insure that we do not loose the HDF5 file if the code 
! is terminated abruptly.
  call h5fclose_f(file_id,ierr)

! Close the HDF5 library and the Fortran90 interface
  call h5close_f(ierr)

#else
  if(istep==ndiag)write(0,*)mype,' **** The code was compiled without HDF5 support ***'
#endif
end subroutine hdf5out_tracked_particles
