program fsynth_main
    use mod_types
    use mod_wav
    use mod_oscillator 
    implicit none

    ! CONFIGURATION
    integer,       parameter :: SAMPLE_RATE = 44100
    integer,       parameter :: DURATION_S  = 5
    real(kind=dp), parameter :: FREQ_HZ     = 440.0_dp
    integer :: wave_choice  

    ! VARIABLES
    type(oscillator_t)         :: osc
    real(kind=dp), allocatable :: audio_buffer(:)
    integer                    :: n_samples, i
    real(kind=dp)              :: t
    

    print *, "Choose your waveform:"
    print *, "  0: Sine (Pure)"
    print *, "  1: Sawtooth (Buzzy)"
    print *, "  2: Square (Gameboy)"
    print *, "  3: Triangle (Flute-like)"
    print *, "---------------------------------------"
    
    ! The 'advance="no"' part keeps the cursor on the same line (like print vs println)
    write(*, '(A)', advance="no") "Enter choice (0-3): "
    read(*, *) wave_choice

    if (wave_choice < 0 .or. wave_choice > 3) then
        print *, "[ERROR] Invalid choice. Defaulting to Sine (0)."
        wave_choice = 0
    end if

    ! INITIALIZATION
    n_samples = SAMPLE_RATE * DURATION_S
    allocate(audio_buffer(n_samples))

    print *, "[INFO] Initializing Oscillator..."
    
    osc = oscillator_t(FREQ_HZ, real(SAMPLE_RATE, kind=dp), 1.0_dp, wave_choice)

    ! SIGNAL GENERATION LOOP
    print *, "[INFO] Rendering..."
    do i = 1, n_samples
        audio_buffer(i) = osc%get_samples()
  
        t = real(i - 1, kind=dp) / real(SAMPLE_RATE, kind=dp)
        audio_buffer(i) = audio_buffer(i) * exp(-1.0_dp * t)
    end do

    call save_wav("output.wav", audio_buffer, SAMPLE_RATE)
    call save_csv("wave_debug.csv", audio_buffer, SAMPLE_RATE, 500)
    
    deallocate(audio_buffer)

end program fsynth_main