!> -----------------------------------------------------------------------------
!> NOTES (FORTRAN SYNTAX): not much experience with fortran :p I keep forgetting syntaxxx (╥﹏╥)
!> 1. parameter: Equivalent to 'const' in C/C++. Value is fixed at compile-time.
!> 2. kind=dp: Ensures the literal number (e.g., 440.0) is stored as 64-bit double.
!> 3. allocatable: Arrays that need explicit memory management (allocate/deallocate).
!> 4. (i - 1): We subtract 1 because audio time starts at 0.0s, but Fortran 
!>             arrays start at index 1.
!> -----------------------------------------------------------------------------

program fsynth_main
    use mod_types
    use mod_wav
    implicit none


    ! 1. CONFIGURATION (CONSTANTS)

    integer,       parameter :: SAMPLE_RATE = 44100   ! Standard CD Quality
    integer,       parameter :: DURATION_S  = 5     ! Seconds
    real(kind=dp), parameter :: FREQ_HZ     = 440.0_dp ! Note A4
    real(kind=dp), parameter :: PI          = 3.1415926535897932_dp


    ! 2. VARIABLES
    real(kind=dp), allocatable :: audio_buffer(:) ! The "Sound" Array
    integer                    :: n_samples       ! Total array size
    integer                    :: i               ! Loop counter
    real(kind=dp)              :: t               ! Current time (seconds)


    ! 3. INITIALIZATION

    n_samples = SAMPLE_RATE * DURATION_S
    
    ! Reserve memory for the audio data
    allocate(audio_buffer(n_samples))

    print *, "[INFO] Synthesizing:", DURATION_S, "s of", FREQ_HZ, "Hz Sine Wave"
    print *, "[INFO] Total Samples:", n_samples


    ! 4. SIGNAL GENERATION 

    ! We iterate through every single sample point.
    ! Formula: y(t) = sin(2 * pi * f * t) * envelope(t)
    do i = 1, n_samples
        
        ! Convert Sample Index -> Time in Seconds
        ! We use `real(..., kind=dp)` to force floating-point division.
        t = real(i - 1, kind=dp) / real(SAMPLE_RATE, kind=dp)
        
        ! A. Generate the Oscillator (The Tone)
        audio_buffer(i) = sin(2.0_dp * PI * FREQ_HZ * t)
        
        ! B. Apply Envelope 
        !Envelope means gradually reduce volume over time.
        ! Exponential Decay: exp(-k * t). Higher 'k' means faster fade out.
        !audio_buffer(i) = audio_buffer(i) * exp(-2.0_dp * t)
        
    end do


    ! 5. OUTPUT

    call save_wav("output.wav", audio_buffer, SAMPLE_RATE)
    
    deallocate(audio_buffer)

end program fsynth_main