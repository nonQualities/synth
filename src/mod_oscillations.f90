module oscillations
    use mod_types
    use mod_wav

    implicit none

    !types:
    type, public :: oscillations_t !apparently its a convention in fortran to name types with _t suffix
        real(kind=dp)              :: frequency_hz
        real(kind=dp)              :: amplitude
        real(kind=dp)              :: phase
        integer                    :: waveform_type ! 0: Sine, 1: Square, 2: Triangle, 3: Sawtooth
        contains 
            procedure              :: get_samples
    end type oscillations_t

    ! interfaces in Fortran are similar to abstract classes in other languages
    ! here, we need to define an interface for the constructor of oscillations_t which works by defining a module procedure which initializes the type, by convention named init_<type_name>. 
    interface oscillations_t
        module procedure init_oscillation
    end interface
contains
    !constructor implementation
    function init_oscillation(frequency_hz, amplitude, phase, waveform_type) result(this)
        real(kind=dp), intent(in)  :: frequency_hz
        real(kind=dp), intent(in)  :: amplitude
        real(kind=dp), intent(in)  :: phase
        integer,       intent(in)  :: waveform_type
        type(oscillations_t)       :: this

        this%frequency_hz          = frequency_hz
        this%amplitude             = amplitude
        this%phase                 = phase
        this%waveform_type         = waveform_type
    end function init_oscillation

    !method to generate samples based on the oscillation parameters
    function get_samples(this) result (samples)
        class(oscillations_t), intent(inout) :: this
        real(kind=dp)                        :: samples
        real(kind=dp)                        :: step
        real(kind=dp), parameter :: PI = 3.1415926535897932_dp
        
        !step calculation
        step = this%frequency_hz / samples

    end function get_samples
end module oscillations