module mod_oscillator
    use mod_types
    implicit none
    
    private
    public :: oscillator_t

   
    ! TYPE DEFINITION
   
    type, public :: oscillator_t
        ! State Variables
        real(kind=dp) :: frequency_hz
        real(kind=dp) :: sample_rate    
        real(kind=dp) :: amplitude
        real(kind=dp) :: phase          ! Range [0.0, 1.0)
        integer       :: waveform_type  ! 0=Sine, 1=Saw, 2=Square, 3=Tri
    contains 
        ! Methods
        procedure :: get_samples
    end type oscillator_t

   
    ! CONSTRUCTOR INTERFACE
   
    interface oscillator_t
        module procedure init_oscillator
    end interface

contains

   
    ! CONSTRUCTOR IMPLEMENTATION
   
    function init_oscillator(freq, rate, amp, wave_type) result(this)
        real(kind=dp), intent(in) :: freq
        real(kind=dp), intent(in) :: rate
        real(kind=dp), intent(in) :: amp
        integer,       intent(in) :: wave_type
        type(oscillator_t)        :: this

        this%frequency_hz  = freq
        this%sample_rate   = rate
        this%amplitude     = amp
        this%waveform_type = wave_type
        
        ! Always start phase at 0.0
        this%phase         = 0.0_dp
    end function init_oscillator

   
    ! METHOD: GET NEXT SAMPLE
   
    function get_samples(this) result(sample_out)
        class(oscillator_t), intent(inout) :: this
        real(kind=dp) :: sample_out
        
        ! Local calculation variables
        real(kind=dp) :: step
        real(kind=dp) :: raw_sample
        real(kind=dp), parameter :: PI = 3.1415926535897932_dp

        ! 1. Calculate Step Size (Delta)
        ! This tells us how much of the waveform cycle we complete in one sample
        step = this%frequency_hz / this%sample_rate

        ! Generation of Raw Waveform (-1.0 to 1.0) based on Phase
        select case (this%waveform_type)
        
        case (0) ! Sine Wave
            ! Map phase 0..1 to radians 0..2PI
            raw_sample = sin(2.0_dp * PI * this%phase)
            
        case (1) ! Sawtooth Wave
            ! Linear ramp from -1 to 1
            ! Formula: 2 * phase - 1
            raw_sample = 2.0_dp * this%phase - 1.0_dp
            
        case (2) ! Square Wave
            ! High if phase < 0.5, Low otherwise
            if (this%phase < 0.5_dp) then
                raw_sample = 1.0_dp
            else 
                raw_sample = -1.0_dp
            end if
            
        case (3) ! Triangle Wave
            ! Starts at 1, goes to -1, back to 1.
            ! Formula: 4 * abs(phase - 0.5) - 1
            raw_sample = 4.0_dp * abs(this%phase - 0.5_dp) - 1.0_dp
            
        case default
            raw_sample = 0.0_dp
        end select

        !  Apply Amplitude
        sample_out = raw_sample * this%amplitude

        !  Update Phase for NEXT time (The Accumulator)
        this%phase = this%phase + step

        ! Wrap Around (Modulo)
        ! If we go past 1.0, wrap back to the start
        if (this%phase >= 1.0_dp) then
            this%phase = this%phase - 1.0_dp
        end if

    end function get_samples

end module mod_oscillator