PROGRAM analyze

  USE iso_c_binding

  IMPLICIT NONE

  INCLUDE 'mpif.h'

  INTEGER, PARAMETER :: i_knd = SELECTED_INT_KIND( 8 )

  INTEGER, PARAMETER :: r_knd = SELECTED_REAL_KIND( 13 )

  REAL(r_knd), PARAMETER :: zero = 0.0_r_knd

  REAL(r_knd), ALLOCATABLE,   DIMENSION(:,:,:,:) :: tmp

  REAL(r_knd), ALLOCATABLE, DIMENSION(:) :: pop, res

  REAL(r_knd), POINTER, DIMENSION(:,:,:,:) :: flux

  REAL(r_knd), POINTER, DIMENSION(:) :: v

  INTEGER(i_knd) :: g, ierr, ng, nx, ny, nz, cy, otno, root, nproc, iproc, fin

  REAL(r_knd) :: dx, dy, dz  

  CHARACTER(len=32) :: arg

  type(c_ptr) :: cptr1, cptr2

  CALL MPI_INIT(ierr)

  root=0;

  CALL getarg(1, arg)
  read(arg,*) nproc

  CALL MPI_COMM_SIZE ( MPI_COMM_WORLD, nproc, ierr )
  CALL MPI_COMM_RANK ( MPI_COMM_WORLD, iproc, ierr )

  CALL setup(nx, ny, nz, ng, dz, dy, dz, iproc)

  ALLOCATE( tmp(nx,ny,nz,ng), STAT=ierr)
  ALLOCATE( pop(ng), STAT=ierr)
  ALLOCATE( res(ng), STAT=ierr)  

  CALL shm_allocate(cptr1, cptr2, cy, fin)

  loop: DO WHILE ( fin == 0)
     CALL C_F_POINTER(cptr1, flux, [nx,ny,nz,ng])
     CALL C_F_POINTER(cptr2, v, [ng])

     pop=zero
     tmp = flux*dx*dy*dz

     DO g=1, ng
        pop(g) = SUM(tmp(:,:,:,g))
     END DO

     CALL MPI_REDUCE(pop, res, ng, MPI_REAL8, MPI_SUM, root, MPI_COMM_WORLD, ierr)

     pop = pop/v
     
     IF(iproc == root) THEN
        WRITE ( *,* ) cy,":"
        DO g=1, ng
           WRITE ( *,* ) pop(g)
        END DO
     END IF
     CALL unlink_shm
     CALL shm_allocate(cptr1, cptr2, cy, fin)
  END DO loop
  CALL unlink_shm
  CALL shm_close
  CALL MPI_FINALIZE ( ierr )
END PROGRAM analyze
