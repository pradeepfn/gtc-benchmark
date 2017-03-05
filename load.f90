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

subroutine load
  use global_parameters
  use particle_array
  use field_array
  use particle_tracking
  use particle_decomp
  implicit none

  integer i,m,ierr
  real(wp) :: c0=2.515517,c1=0.802853,c2=0.010328,&
              d1=1.432788,d2=0.189269,d3=0.001308
  real(wp) :: w_initial,energy,momentum,r,rmi,pi2_inv,delr,ainv,vthe,tsqrt,&
              vthi,cost,b,upara,eperp,cmratio,z4tmp

! Initialize random number generator
  call rand_num_gen_init

! restart from previous runs
  if(irun /= 0)then
     call restart_read
     return
  endif

  !!rmi=1.0/real(mi)
  rmi=1.0/real(mi*npartdom)
  pi2_inv=0.5/pi
  delr=1.0/deltar
  ainv=1.0/a
  w_initial=1.0e-3
  if(nonlinear<0.5)w_initial=1.0e-12
  if(track_particles < -10 .and. track_particles > -20)w_initial=0.1_wp*real(-10-track_particles,wp)
  if(mype==0)write(0,*)'w_initial =',w_initial
  ntracer=0
  !if(mype==0)ntracer=mi
  if(mype==0)ntracer=1
      
! radial: uniformly distributed in r^2, later transform to psi
!$omp parallel do private(m)
  do m=1,mi
     !!zion(1,m)=sqrt(a0*a0+(real(m)-0.5)*(a1*a1-a0*a0)*rmi)
     zion(1,m)=sqrt(a0*a0+(real(m+myrank_partd*mi)-0.5)*(a1*a1-a0*a0)*rmi)
  enddo

! If particle tracking is "on", tag each particle with a unique number
  if(track_particles == 1)call tag_particles

! Set zion(2:6,1:mi) to uniformly distributed random values between 0 and 1
  call set_random_zion

! poloidal: uniform in alpha=theta_0+r*sin(alpha_0), theta_0=theta+r*sin(theta)
!$omp parallel do private(m)
  do m=1,mi                
     zion(2,m)=2.0*pi*(zion(2,m)-0.5)
     zion0(2,m)=zion(2,m) !zion0(2,:) for temporary storage
  enddo
  do i=1,10
!$omp parallel do private(m)
     do m=1,mi
        zion(2,m)=zion0(2,m)-2.0*zion(1,m)*sin(zion(2,m))
     enddo
  enddo
!$omp parallel do private(m)
  do m=1,mi                
     zion(2,m)=zion(2,m)*pi2_inv+10.0 !period of 1
     zion(2,m)=2.0*pi*(zion(2,m)-aint(zion(2,m))) ![0,2*pi)
  enddo

! Maxwellian distribution in v_para, <v_para^2>=1.0, use zion0(4,:) as temporary storage
!$omp parallel do private(m)
  do m=1,mi                
     z4tmp=zion(4,m)
     zion(4,m)=zion(4,m)-0.5
     zion0(4,m)=sign(1.0,zion(4,m))
     zion(4,m)=sqrt(max(1.0e-20,log(1.0/max(1.0e-20,zion(4,m)**2))))
     zion(4,m)=zion(4,m)-(c0+c1*zion(4,m)+c2*zion(4,m)**2)/&
          (1.0+d1*zion(4,m)+d2*zion(4,m)**2+d3*zion(4,m)**3)
     if(zion(4,m)>umax)zion(4,m)=z4tmp
  enddo

!$omp parallel do private(m)
  do m=1,mi

! toroidal:  uniformly distributed in zeta
     zion(3,m)=zetamin+(zetamax-zetamin)*zion(3,m)

     zion(4,m)=zion0(4,m)*min(umax,zion(4,m))

! initial random weight
     zion(5,m)=2.0*w_initial*(zion(5,m)-0.5)*(1.0+cos(zion(2,m)))

! Maxwellian distribution in v_perp, <v_perp^2>=1.0
     zion(6,m)=max(1.0e-20,min(umax*umax,-log(max(1.0e-20,zion(6,m)))))
  enddo

! transform zion(1,:) to psi, zion(4,:) to rho_para, zion(6,:) to sqrt(mu) 
  vthi=gyroradius*abs(qion)/aion
!$omp parallel do private(m)
  do m=1,mi
     zion0(1,m)=1.0/(1.0+zion(1,m)*cos(zion(2,m))) !B-field
     zion(1,m)=0.5*zion(1,m)*zion(1,m)
     zion(4,m)=vthi*zion(4,m)*aion/(qion*zion0(1,m))
     zion(6,m)=sqrt(aion*vthi*vthi*zion(6,m)/zion0(1,m))
  enddo

! tracer particle initially resides on PE=0
  if(mype == 0)then
     zion(1,ntracer)=0.5*(0.5*(a0+a1))**2
     zion(2,ntracer)=0.0
     zion(3,ntracer)=0.5*(zetamin+zetamax)
     zion(4,ntracer)=0.5*vthi*aion/qion
     zion(5,ntracer)=0.0
     zion(6,ntracer)=sqrt(aion*vthi*vthi)
!     zion0(1:5,ntracer)=zion(1:5,ntracer)
  endif

! Special case to test a "full-F"-like simulation. We set the weight of
! all the particles to 1.
  if(track_particles == -30)then
     if(mype==0)then
        write(0,*)'*********************************'
        write(0,*)'   SETTING WEIGHTS TO 1'
        write(0,*)'*********************************'
     endif
     do m=1,mi
        zion(5,m)=1.0_wp
     enddo
  endif

  if(iload==0)then
! uniform loading
!$omp parallel do private(m)
     do m=1,mi
        zion0(6,m)=1.0
     enddo
  else
! true nonuniform for temperature profile, density profile by weight
!$omp parallel do private(m)
     do m=1,mi
        r=sqrt(2.0*zion(1,m))
        i=max(0,min(mpsi,int((r-a0)*delr+0.5)))
        zion(4,m)=zion(4,m)*sqrt(rtemi(i))
        zion(6,m)=zion(6,m)*sqrt(rtemi(i))
        zion0(6,m)=max(0.1,min(10.0,rden(i)))
     enddo
  endif
  
! load electron on top of ion if mi=me
  if(nhybrid>0)then
     vthe=sqrt(aion/(aelectron*tite))*(qion/aion)*(aelectron/qelectron)
     tsqrt=sqrt(1.0/tite)

     cmratio=qion/aion
     me=0
     do m=1,mi
        r=sqrt(2.0*zion(1,m))
        cost=cos(zion(2,m))
        b=1.0/(1.0+r*cost)
        upara=zion(4,m)*b*cmratio
        energy=0.5*aion*upara*upara+zion(6,m)*zion(6,m)*b
        eperp=zion(6,m)*zion(6,m)/(1.0-r)
        if(eperp>energy)then     ! keep trapped electrons
           me=me+1
           zelectron(1,me)=zion(1,m)
           zelectron(2,me)=zion(2,m)
           zelectron(3,me)=zion(3,m)
           zelectron(4,me)=zion(4,m)*vthe
           zelectron(5,me)=zion(5,m)
           zelectron(6,me)=zion(6,m)*tsqrt
           zelectron0(6,me)=zion0(6,m)
        endif
     enddo
     if(mype == 0)then
        ntracer=me
!        zelectron0(1:5,ntracer)=zelectron(1:5,ntracer)
     endif
  endif

!  write(mype+40,'(6e15.6)')zion(1:6,1:mi)
!  do m=1,mi
!     write(mype+40,*)zion(:,m)
!  enddo
!  close(mype+40)

end subroutine load


