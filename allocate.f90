module Allocator
    USE, INTRINSIC :: ISO_C_BINDING
    interface
        type(c_ptr) function alloc(vsize, varname, pid, cmtsize) bind(C)
            USE, INTRINSIC :: ISO_C_BINDING
            integer(KIND=C_INT) :: vsize
            character(KIND=C_CHAR) :: varname(10)
            integer(KIND=C_INT) :: pid, cmtsize
        end function alloc
    end interface

contains
    subroutine alloc_1d_real(arr,row,varname, mype, cmtsize)
        integer :: row
        real, pointer :: arr(:)
        type(c_ptr) :: cptr
        integer :: val, nvsize
        character(len=10) varname
        integer :: mype, cmtsize

        val = row*SIZEOF(real)
        nvsize = cmtsize * SIZEOF(real)
        cptr = alloc(val,varname, mype, nvsize)
        call c_f_pointer(cptr,arr,[row])
    end subroutine

    subroutine alloc_2d_real(arr,row,col,varname, mype, cmtsize)
        integer :: row
        integer :: col
        integer :: mype, cmtsize
        real, pointer :: arr(:,:)
        type(c_ptr) :: cptr
        integer :: val, nvsize
        character(len=10) varname

        val = row*col*SIZEOF(real)
        nvsize = cmtsize * SIZEOF(real)
        cptr = alloc(val,varname, mype, nvsize)
        call c_f_pointer(cptr,arr,[row,col])
    end subroutine

    subroutine alloc_2d_int(arr,row,col,varname, mype, cmtsize)
        integer :: row
        integer :: col
        integer :: mype, cmtsize
        integer, pointer :: arr(:,:)
        type(c_ptr) :: cptr
        integer :: val, nvsize
        character(len=10) varname

        val = row*col*SIZEOF(real)
        nvsize = cmtsize * SIZEOF(real)
        cptr = alloc(val,varname, mype, nvsize)
        call c_f_pointer(cptr,arr,[row,col])
    end subroutine


    subroutine alloc_3d_int(arr,row,col,z,varname, mype, cmtsize)
        integer :: row
        integer :: col
        integer :: z
        integer :: mype, cmtsize
        integer, pointer :: arr(:,:, :)
        type(c_ptr) :: cptr
        integer :: val, nvsize
        character(len=10) varname

        val = row*col* z*SIZEOF(real)
        nvsize = cmtsize * SIZEOF(real)
        cptr = alloc(val,varname, mype, nvsize)
        call c_f_pointer(cptr,arr,[row,col,z])
    end subroutine



    subroutine alloc_3d_real(arr,row,col,z,varname, mype, cmtsize)
        integer :: row
        integer :: col
        integer :: z
        integer :: mype, cmtsize
        real, pointer :: arr(:,:,:)
        type(c_ptr) :: cptr
        integer :: val, nvsize
        character(len=10) varname

        nvsize = cmtsize * SIZEOF(real)
        val = row*col*z*SIZEOF(real)
        cptr = alloc(val,varname, mype, nvsize)
        call c_f_pointer(cptr,arr,[row,col,z])
    end subroutine

    subroutine free_1d_real(arr)
        real, pointer :: arr(:)
        call afree(arr)
    end subroutine
end module
