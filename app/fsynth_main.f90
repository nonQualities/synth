program fsynth_main
    use mod_types
    use mod_wav
    use mod_oscillator 
    use mod_adsr
    implicit none


    ! 1. CONFIGURATION

    integer,       parameter :: SAMPLE_RATE = 44100
    integer,       parameter :: DURATION_S  = 5
    real(kind=dp), parameter :: FREQ_HZ     = 440.0_dp
    
    ! User Input Variables
    integer       :: wave_choice
    real(kind=dp) :: in_attack, in_decay, in_sustain, in_release


    ! 2. VARIABLES

    type(oscillator_t)         :: osc
    type(adsr_t)               :: env
    real(kind=dp), allocatable :: audio_buffer(:)
    real(kind=dp)              :: current_amp
    integer                    :: n_samples, i, release_index


    ! 3. USER INPUT INTERFACE

    print *, "========================================"
    print *, "      F-SYNTH: PARAMETER SETUP"
    print *, "========================================"
    
    ! -- Waveform Selection --
    print *, "1. Choose Waveform:"
    print *, "   0: Sine"
    print *, "   1: Sawtooth"
    print *, "   2: Square"
    print *, "   3: Triangle"
    write(*, '(A)', advance="no") "   > Enter choice (0-3): "
    read(*, *) wave_choice
    if (wave_choice < 0 .or. wave_choice > 3) wave_choice = 0

    print *, "----------------------------------------"
    
    ! -- ADSR Selection --
    print *, "2. Envelope Settings (ADSR):"
    
    write(*, '(A)', advance="no") "   > Attack Time (sec) [e.g. 0.1]: "
    read(*, *) in_attack
    
    write(*, '(A)', advance="no") "   > Decay Time  (sec) [e.g. 0.2]: "
    read(*, *) in_decay
    
    write(*, '(A)', advance="no") "   > Sustain Lvl (0.0-1.0) [e.g. 0.7]: "
    read(*, *) in_sustain
    
    write(*, '(A)', advance="no") "   > Release Time (sec) [e.g. 1.0]: "
    read(*, *) in_release

    ! -- Safety Clamping --
    ! Ensure Sustain is valid (0.0 to 1.0)
    if (in_sustain > 1.0_dp) in_sustain = 1.0_dp
    if (in_sustain < 0.0_dp) in_sustain = 0.0_dp
    ! Ensure times are not negative
    if (in_attack < 0.0_dp) in_attack = 0.01_dp
    if (in_decay < 0.0_dp)  in_decay  = 0.01_dp
    if (in_release < 0.0_dp) in_release = 0.01_dp


    ! 4. INITIALIZATION

    n_samples = SAMPLE_RATE * DURATION_S
    allocate(audio_buffer(n_samples))

    print *, "----------------------------------------"
    print *, "[INFO] Initializing Engine..."

    ! Init Oscillator with user choice
    osc = oscillator_t(FREQ_HZ, real(SAMPLE_RATE, kind=dp), 1.0_dp, wave_choice)

    ! Init Envelope with user inputs
    env = adsr_t(in_attack, in_decay, in_sustain, in_release, real(SAMPLE_RATE, kind=dp))

    ! We will hold the key for half the duration, then release
    release_index = (DURATION_S / 2.0) * SAMPLE_RATE


    ! 5. RENDER LOOP

    print *, "[INFO] Rendering Audio..."
    call env%note_on()

    do i = 1, n_samples
        
        ! Trigger Release halfway through
        if (i == release_index) call env%note_off()

        ! Get Envelope Level
        current_amp = env%get_next_level()

        ! Mix
        audio_buffer(i) = osc%get_samples() * current_amp
        
    end do


    ! 6. SAVE

    call save_wav("output.wav", audio_buffer, SAMPLE_RATE)
    
    ! Save a longer debug slice (1 sec) to verify the envelope visually
    call save_csv("wave_debug.csv", audio_buffer, SAMPLE_RATE, 44100)
    
    deallocate(audio_buffer)
    print *, "[SUCCESS] Saved to output.wav"

end program fsynth_main