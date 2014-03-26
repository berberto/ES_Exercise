!
! Copyright (C) 2013 A. Dal Corso 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
PROGRAM cb_charge
!
!  This program reads from input the name of a crystal (Si, Ge, Sn, GaAs,
!  or InSb) and a mesh k points in the fcc Brillouin zone, and writes 
!  on output the Cohen-Bergstresser charge density along a line or
!  in a plane of points. 
!  Reference: Phys. Rev. 141, 789 (1966).
!
USE kinds, ONLY : dp
USE cbmod, ONLY : crystal_name, at, bg, ecut, gcutm2, nks, xk, npw, &
                  ngm, nbnd, h, evc, et, nir, r, nbnd_occ, &
                  nk1, nk2, nk3, rho, alat, dimen, rx, ry, nir_x, nir_y
IMPLICIT NONE
INTEGER :: ik, ios, ibnd, jbnd, ir, jr, ijr
!
!  Read the input
!
CALL input_cb()
!
! set the cb parameters and the size of the unit cell
!
CALL set_cb_parameters(crystal_name)
!
! set the direct and reciprocal lattice vectors of the fcc lattice
!
CALL set_lattice(at, bg, 'fcc')
!
! set the coordinates of the mesh of k points
!
CALL kgen(nk1, nk2, nk3, bg)
!
! given ecut and the k-points, calculate the radius of the sphere in
! reciprocal space that contains all the necessary G vectors.
!
CALL calculate_radius(ecut, xk, nks, gcutm2)
!
! compute all the reciprocal lattice vectors within a sphere of radius
! sqrt(gcutm2)
!
CALL ggen(gcutm2)
!
! open the output file
!
OPEN(unit=26,file='output',status='unknown',err=100,iostat=ios)
100 IF (ios /= 0) STOP 'opening output'
!
!  For all k points compute and diagonalize the Hamiltonian
!
ALLOCATE(rho(nir))
rho=0.0_DP
DO ik=1, nks
   IF (mod(ik,10)==0) write(6,*) ik, nks
!
!   set the Hamiltonian 
!
   CALL set_hamiltonian(xk(:,ik), ecut)
!
!   and diagonalize it. nbnd bands are calculated.
!
   CALL diagonalize(npw, nbnd, h, et, evc)
!
!  compute charge density
!
   CALL accumulate_charge(evc, rho)
!
!  deallocate the Hamiltonian variables
!
   CALL deallocate_hamiltonian()
ENDDO
!
!   write on output the charge density
!
IF (dimen==1) THEN
   DO ir = 1, nir
      WRITE(26,'(2f16.9)') rx(ir), rho(ir) / nks !* 4.0_DP / alat**3 
   ENDDO
ELSEIF (dimen==2) THEN
   ijr=0
   DO ir = 1, nir_x
      DO jr = 1, nir_y
         ijr = ijr + 1
         WRITE(26,'(3f16.9)') rx(ir), ry(jr), rho(ijr) / nks !* 4.0_DP / alat**3 
      ENDDO
   ENDDO
ENDIF
CALL deallocate_all()
CLOSE(26)
END PROGRAM cb_charge
