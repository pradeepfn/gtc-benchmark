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

subroutine snapshot
  use global_parameters
  use particle_array
  use particle_decomp
  use field_array
  use diagnosis_array
  implicit none
  
  integer,parameter :: mbin_psi=5, mbin_u=41
  integer i,ibin,ip,iu,j,jj,jm,jt,k,kz,m,nsnap,ierror,icount
  real(wp) eright,uright,uleft,pdum,tdum,b,upara,energy,pitch,q,dela,delu,&
       qdum,r,vthi_inv,delr,delz,phisn(mzeta,mtheta(mpsi/2)),&
       eachpsi(mtheta(mpsi/2)*mzetamax),vthe_inv,aion_inv,ae_inv,wt,&
       delt(0:mpsi),weight,adum(0:mpsi),bdum(mbin_u,mbin_psi)
  real(wp) ubin_max,pbin_max,ebin_max
  real(wp),dimension(0:mpsi) :: marker,fflows,dflows,ftem,dtem
  real(wp),dimension(mbin_u,mbin_psi) :: ubin,dubin,pbin,dpbin,ebin,debin
!  real(wp),dimension(mzeta,0:mpsi,0:mthetamax) :: ftotal,tpara,tperp
  real(wp),external :: boozer2x,boozer2z,r2psi
  character(len=11) date,time
  character(len=13) cdum

! write particle data for re-run
  call restart_write

! number of poloidal grid
  jm=mtheta(mpsi/2)

! zion space grids: parallel velocity, kinetic energy, pitch angle
  uright=umax
  uleft=-uright  
  dela=real(mbin_psi)/(a1-a0)
  delu=1.0/(uright-uleft)
  eright=1.0/(umax*umax/4.0)
  vthi_inv=aion/(gyroradius*abs(qion))
  vthe_inv=vthi_inv*sqrt(tite*aelectron/aion)
  aion_inv=1.0/aion
  ae_inv=1.0/aelectron
  delr=1.0/deltar
  delt=1.0/deltat
  delz=1.0/deltaz

! radial and 3-d volume data
  ubin=0.0
  pbin=0.0
  ebin=0.0
  dubin=0.0
  dpbin=0.0
  debin=0.0
  marker=0.0
  fflows=0.0
  dflows=0.0
  ftem=0.0
  dtem=0.0
!  ftotal=0.0
!  tpara=0.0
!  tperp=0.0

  if(nhybrid==0)then

     do m=1,mi 
        weight=zion0(6,m)

        r=sqrt(2.0*zion(1,m))
        ibin=max(1,min(mbin_psi,1+int((r-a0)*dela)))
        ip=max(0,min(mpsi,int((r-a0)*delr+0.5)))
        jt=max(0,min(mtheta(ip),int(zion(2,m)*delt(ip)+0.5)))
        kz=max(1,min(mzeta,1+int((zion(3,m)-zetamin)*delz)))
     
        b=1.0/(1.0+r*cos(zion(2,m)))
        upara=zion(4,m)*b*qion*aion_inv*vthi_inv !normalized by v_thi
        energy=max(1.0e-20,0.5*upara*upara+&
             zion(6,m)*zion(6,m)*b*aion_inv*vthi_inv*vthi_inv) !normalized by T_i
        pitch=upara/sqrt(2.0*energy)
     
        !iu=max(1,min(mbin_u,1+int(real(mbin_u)*(upara-uleft)*delu)))
        iu=1+int(real(mbin_u-1)*(upara-uleft)*delu)
        if(iu >= 1 .and. iu <= mbin_u)then
           ubin(iu,ibin)=ubin(iu,ibin)+weight
           dubin(iu,ibin)=dubin(iu,ibin)+zion(5,m)
        endif
     
        !iu=max(1,min(mbin_u,1+int(real(mbin_u)*energy*eright)))
        iu=1+int(real(mbin_u-1)*energy*eright)
        if(iu >= 1 .and. iu <= mbin_u)then
           ebin(iu,ibin)=ebin(iu,ibin)+weight
           debin(iu,ibin)=debin(iu,ibin)+zion(5,m)
        endif
        
        !iu=max(1,min(mbin_u,1+int(real(mbin_u)*0.5*(pitch+1.0))))
        iu=1+int(real(mbin_u-1)*0.5*(pitch+1.0))
        if(iu >= 1 .and. iu <= mbin_u)then
           pbin(iu,ibin)=pbin(iu,ibin)+weight
           dpbin(iu,ibin)=dpbin(iu,ibin)+zion(5,m)
        endif
        
! radial profile of marker, v_para, and temperature
        marker(ip)=marker(ip)+weight
        fflows(ip)=fflows(ip)+upara*weight
        dflows(ip)=dflows(ip)+zion(5,m)*upara
        ftem(ip)=ftem(ip)+energy*weight
        dtem(ip)=dtem(ip)+zion(5,m)*energy
     
! parallel and perpendicular pressure perturbation
!     ftotal(kz,ip,jt)=ftotal(kz,ip,jt)+weight
!     tpara(kz,ip,jt)=tpara(kz,ip,jt)+zion(5,m)*0.5*upara*upara
!     tperp(kz,ip,jt)=tperp(kz,ip,jt)+zion(5,m)*energy
     enddo
  
  else

     do m=1,me 
        weight=zelectron0(6,m)

        r=sqrt(2.0*zelectron(1,m))
        ibin=max(1,min(mbin_psi,1+int((r-a0)*dela)))
        ip=max(0,min(mpsi,int((r-a0)*delr+0.5)))
        jt=max(0,min(mtheta(ip),int(zelectron(2,m)*delt(ip)+0.5)))
        kz=max(1,min(mzeta,1+int((zelectron(3,m)-zetamin)*delz)))
     
        b=1.0/(1.0+r*cos(zelectron(2,m)))
        upara=zelectron(4,m)*b*qelectron*ae_inv*vthe_inv
        energy=max(1.0e-20,0.5*upara*upara+&
             zelectron(6,m)*zelectron(6,m)*b*ae_inv*vthe_inv*vthe_inv)
        pitch=upara/sqrt(2.0*energy)
     
        iu=max(1,min(mbin_u,1+int(real(mbin_u)*(upara-uleft)*delu)))
        ubin(iu,ibin)=ubin(iu,ibin)+weight
        dubin(iu,ibin)=dubin(iu,ibin)+zelectron(5,m)
     
        iu=max(1,min(mbin_u,1+int(real(mbin_u)*energy*eright)))
        ebin(iu,ibin)=ebin(iu,ibin)+weight
        debin(iu,ibin)=debin(iu,ibin)+zelectron(5,m)
        
        iu=max(1,min(mbin_u,1+int(real(mbin_u)*0.5*(pitch+1.0))))
        pbin(iu,ibin)=pbin(iu,ibin)+weight
        dpbin(iu,ibin)=dpbin(iu,ibin)+zelectron(5,m)
        
! radial profile of marker, v_para, and temperature
        marker(ip)=marker(ip)+weight
        fflows(ip)=fflows(ip)+upara*weight
        dflows(ip)=dflows(ip)+zelectron(5,m)*upara
        ftem(ip)=ftem(ip)+energy*weight
        dtem(ip)=dtem(ip)+zelectron(5,m)*energy
    
! parallel and perpendicular pressure perturbation
!     ftotal(kz,ip,jt)=ftotal(kz,ip,jt)+weight
!     tpara(kz,ip,jt)=tpara(kz,ip,jt)+zelectron(5,m)*0.5*upara*upara
!     tperp(kz,ip,jt)=tperp(kz,ip,jt)+zelectron(5,m)*energy
     enddo

  endif

!  do i=0,mpsi
!     tpara(:,i,mtheta(i))=tpara(:,i,mtheta(i))+tpara(:,i,0)
!     tperp(:,i,mtheta(i))=tperp(:,i,mtheta(i))+tperp(:,i,0)
!     ftotal(:,i,mtheta(i))=ftotal(:,i,mtheta(i))+ftotal(:,i,0)
!  enddo

! do i=0,mpsi
!    ftotal(:,i,1:mtheta(i))=max(1.0e-6,ftotal(:,i,1:mtheta(i)))
!     tpara(:,i,1:mtheta(i))=tpara(:,i,1:mtheta(i))/ftotal(:,i,1:mtheta(i))
!     tperp(:,i,1:mtheta(i))=tperp(:,i,1:mtheta(i))/ftotal(:,i,1:mtheta(i))
!     ftotal(:,i,1:mtheta(i))=ftotal(:,i,1:mtheta(i))*markeri(:,i,1:mtheta(i))
!     ftotal(:,i,0)=ftotal(:,i,mtheta(i))
!  enddo

  icount=mbin_psi*mbin_u
  call MPI_REDUCE(ubin,bdum,icount,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)ubin=bdum
  call MPI_REDUCE(dubin,bdum,icount,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)dubin=bdum
  call MPI_REDUCE(pbin,bdum,icount,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)pbin=bdum
  call MPI_REDUCE(dpbin,bdum,icount,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)dpbin=bdum
  call MPI_REDUCE(ebin,bdum,icount,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)ebin=bdum
  call MPI_REDUCE(debin,bdum,icount,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)debin=bdum
  call MPI_REDUCE(marker,adum,mpsi+1,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)marker=adum
  call MPI_REDUCE(fflows,adum,mpsi+1,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)fflows=adum
  call MPI_REDUCE(dflows,adum,mpsi+1,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)dflows=adum
  call MPI_REDUCE(ftem,adum,mpsi+1,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)ftem=adum
  call MPI_REDUCE(dtem,adum,mpsi+1,mpi_Rsize,MPI_SUM,0,MPI_COMM_WORLD,ierror)
  if(mype==0)dtem=adum

  where(marker .lt. 1.0)marker=1.0
  fflows=fflows/marker
  dflows=dflows/marker
  ftem=ftem/marker
  dtem=dtem/marker
  marker(1:mpsi)=marker(1:mpsi)*pmarki(1:mpsi)

! gather flux surface profile
  eachpsi=0.0
  do j=1,jm
     phisn(:,j)=phi(1:mzeta,igrid(mpsi/2)+j)
  enddo
  call MPI_GATHER(phisn,jm*mzeta,mpi_Rsize,eachpsi,&
       jm*mzeta,mpi_Rsize,0,toroidal_comm,ierror)
  
  if(mype == 0)then
! normalization
     !dubin=dubin/max(1.0,ubin)
     !dpbin=dpbin/max(1.0,pbin)
     !debin=debin/max(1.0,ebin)
     ubin_max=maxval(ubin)
     pbin_max=maxval(pbin)
     ebin_max=maxval(ebin)
     dubin=dubin/ubin_max
     dpbin=dpbin/pbin_max
     debin=debin/ebin_max
  endif

! record program end time
  if(istep .eq. mstep)then
     call date_and_time(date,time)
     if(mype == 0) then
        if(stdout /= 6 .and. stdout /= 0)open(stdout,file='stdout.out',status='old',position='append')
        write(stdout,*) 'Program ends at DATE=', date, 'TIME=', time
        if(stdout /= 6 .and. stdout /= 0)close(stdout)
     end if
  endif
  
101 format(i6)
102 format(e10.4)
  
end subroutine snapshot

