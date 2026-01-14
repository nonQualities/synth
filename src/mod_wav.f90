!> -----------------------------------------------------------------------------
!> MODULE: mod_wav
!> PURPOSE: Handles the low-level writing of unformatted binary Audio/WAV files.
!>
!> NOTES (FORTRAN CONCEPTS): im still a beginner :)
!> 1. intent(in): Read-only argument. The subroutine cannot modify it.
!> 2. _dp / _i16: Suffixes that force a specific precision (Double / Int16).
!> 3. allocatable: Arrays whose size is determined at runtime, not compile time.
!> 4. newunit=x: Let the compiler pick a free file ID for 'x'.
!> 5. access='stream': Treat file as a raw sequence of bytes (no line breaks).
!> -----------------------------------------------------------------------------
module mod_wav
    use mod_types
    implicit none
    
    private
    public :: save_wav

    ! -- Constants for WAV Format --
    integer(i16), parameter :: PCM_FORMAT   = 1_i16    ! 1 = Linear PCM
    integer(i16), parameter :: MONO         = 1_i16    ! 1 Channel
    integer(i16), parameter :: BITS_PER_SMP = 16_i16   ! 16-bit depth
    integer(i16), parameter :: MAX_AMP      = 32767_i16

contains

    !> Writes an array of floating point samples [-1.0, 1.0] to a WAV file.
    subroutine save_wav(filename, samples, sample_rate)
        character(len=*), intent(in) :: filename
        real(kind=dp),    intent(in) :: samples(:) 
        integer,          intent(in) :: sample_rate
        
        ! Local Variables
        integer(kind=i16), allocatable :: pcm_data(:)
        integer :: file_unit, i
        integer :: data_chunk_size, total_file_size
        
   
        ! QUANTIZATION (Float -> Int16)
        ! We map the continuous range [-1.0, 1.0] to the discrete range 
        ! [-32767, 32767]. We must "clip" values outside this range to 
        ! avoid integer wraparound (which causes nasty digital distortion).

        allocate(pcm_data(size(samples)))
        
        do i = 1, size(samples)
            if (samples(i) > 1.0_dp) then
                pcm_data(i) = MAX_AMP
            else if (samples(i) < -1.0_dp) then
                pcm_data(i) = -MAX_AMP
            else
                ! nint(): Rounds to nearest integer
                pcm_data(i) = nint(samples(i) * real(MAX_AMP, kind=dp), kind=i16) 
            end if
        end do


        ! HEADER CALCULATION
        ! Data Size = NumSamples * NumChannels * BytesPerSample
        data_chunk_size = size(pcm_data) * 2 
        
        ! File Size = Header Overhead (36 bytes) + Data Chunk Size
        total_file_size = 36 + data_chunk_size 

        !  WRITE BINARY FILE

        open(newunit=file_unit, file=filename, access='stream', &
             status='replace', form='unformatted')

        ! RIFF HEADER
        ! Identifies this file as a Resource Interchange File Format (WAVE)
        ! more info: https://docs.fileformat.com/audio/wav/
             
        write(file_unit) "RIFF"             ! ChunkID
        write(file_unit) total_file_size    ! ChunkSize
        write(file_unit) "WAVE"             ! Format

        ! [2] FMT CHUNK (Format specs)
        write(file_unit) "fmt "             ! Subchunk1ID
        write(file_unit) 16                 ! Subchunk1Size (16 for PCM)
        write(file_unit) PCM_FORMAT         ! AudioFormat
        write(file_unit) MONO               ! NumChannels
        write(file_unit) sample_rate        ! SampleRate
        
        ! ByteRate = SampleRate * NumChannels * BytesPerSample/8
        write(file_unit) sample_rate * 2    
        
        ! BlockAlign = NumChannels * BytesPerSample/8
        write(file_unit) 2_i16              
        write(file_unit) BITS_PER_SMP       ! BitsPerSample

        ! [3] DATA CHUNK (The actual sound)
        write(file_unit) "data"             ! Subchunk2ID
        write(file_unit) data_chunk_size    ! Subchunk2Size
        write(file_unit) pcm_data           ! The Array
        
        ! Cleanup
        close(file_unit)
        deallocate(pcm_data)
        
        print *, "  [IO] Saved WAV to: ", filename
        
    end subroutine save_wav

end module mod_wav