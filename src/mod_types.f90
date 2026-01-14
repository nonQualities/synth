module mod_types
    use iso_fortran_env !iso_fortran_env provides standard kinds for integers and reals
    implicit none
    
    ! Internal calculation precision (Double Precision)
    integer, parameter :: dp = real64
    
    ! Audio file output precision (16-bit Integer)
    integer, parameter :: i16 = int16 !i16 means 16 bit integer
end module mod_types