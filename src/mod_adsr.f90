module mod_adsr
    use mod_types
    implicit none
    
    private
    public :: adsr_t

    integer, parameter :: IDLE = 0
    integer, parameter :: ATTACK = 1
    integer, parameter :: DECAY = 2
    integer, parameter :: SUSTAIN = 3
    integer, parameter :: RELEASE = 4

    type, public :: adsr_t
        real(kind=dp) :: attack_time   ! Seconds
        real(kind=dp) :: decay_time    ! Seconds
        real(kind=dp) :: sustain_level ! 0.0 to 1.0
        real(kind=dp) :: release_time  ! Seconds
        real(kind=dp) :: sample_rate
        integer       :: state         
        real(kind=dp) :: current_vol_level 
    contains
        procedure     :: get_next_level
        procedure     :: note_on
        procedure     :: note_off
    end type adsr_t

    interface adsr_t
        module procedure init_adsr
    end interface

contains

    function init_adsr(a, d, s, r, rate) result(this)
        real(kind=dp), intent(in) :: a, d, s, r, rate
        type(adsr_t)              :: this
        
        this%attack_time       = a
        this%decay_time        = d
        this%sustain_level     = s
        this%release_time      = r
        this%sample_rate       = rate
        this%state             = IDLE
        this%current_vol_level = 0.0_dp
    end function init_adsr

  
    subroutine note_on(this)
        class(adsr_t), intent(inout) :: this
        this%state = ATTACK
    end subroutine note_on

    subroutine note_off(this)
        class(adsr_t), intent(inout) :: this
        this%state = RELEASE
    end subroutine note_off


    function get_next_level(this) result(level)
        class(adsr_t), intent(inout) :: this
        real(kind=dp) :: level
        real(kind=dp) :: step
        
        select case (this%state)
        case (IDLE)
            this%current_vol_level = 0.0_dp

        case (ATTACK)
            ! Rate: Distance (1.0) / Steps (Time * Rate)
            step = 1.0_dp / (this%attack_time * this%sample_rate)
            this%current_vol_level = this%current_vol_level + step
            if (this%current_vol_level >= 1.0_dp) then
                this%current_vol_level = 1.0_dp
                this%state = DECAY
            end if

        case (DECAY)
            ! Distance to cover: (1.0 - Sustain)
            step = (1.0_dp - this%sustain_level) / (this%decay_time * this%sample_rate)
            this%current_vol_level = this%current_vol_level - step
            if (this%current_vol_level <= this%sustain_level) then
                this%current_vol_level = this%sustain_level
                this%state = SUSTAIN
            end if

        case (SUSTAIN)
            this%current_vol_level = this%sustain_level

        case (RELEASE)
            ! use the full scale rate for consistent slope
            step = 1.0_dp / (this%release_time * this%sample_rate)
            this%current_vol_level= this%current_vol_level - step
            if (this%current_vol_level <= 0.0_dp) then
                this%current_vol_level = 0.0_dp
                this%state = IDLE
            end if  
        end select

        level = this%current_vol_level
        
    end function get_next_level
        
end module mod_adsr