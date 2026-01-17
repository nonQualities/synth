## for ADSR direct reference was taken from :
[Envelope Generator](https://www.earlevel.com/main/2013/06/02/envelope-generators-adsr-part-2/)


# `mod_adsr` — ADSR Envelope Generator (Fortran)

## Overview

`mod_adsr` implements a classic **ADSR (Attack–Decay–Sustain–Release)** envelope generator suitable for audio synthesis.
It is designed to be **sample-accurate**, **state-based**, and **self-contained**, with explicit control over envelope timing and progression.

The envelope advances **one sample at a time** via `get_next_level`, making it appropriate for real-time DSP loops.



## Features

* Sample-rate aware envelope progression
* Explicit state machine (IDLE, ATTACK, DECAY, SUSTAIN, RELEASE)
* Linear segments for all envelope phases
* Object-oriented Fortran design using derived types and type-bound procedures
* Deterministic and stateless outside its own internal memory



## Module Interface

```fortran
module mod_adsr
```

### Dependencies

* `mod_types`

  * Provides the `dp` kind (double precision floating point)



## ADSR States

The envelope is implemented as a finite-state machine using integer constants:

| State Name | Value | Description                           |
| ---------- | ----- | ------------------------------------- |
| `IDLE`     | 0     | Envelope inactive, output is 0.0      |
| `ATTACK`   | 1     | Linear rise from current level to 1.0 |
| `DECAY`    | 2     | Linear fall from 1.0 to sustain level |
| `SUSTAIN`  | 3     | Hold sustain level indefinitely       |
| `RELEASE`  | 4     | Linear fall to 0.0                    |



## Derived Type: `adsr_t`

```fortran
type, public :: adsr_t
```

### Public Parameters (User Controls)

| Field           | Type       | Description                 |
| --------------- | ---------- | --------------------------- |
| `attack_time`   | `real(dp)` | Attack duration in seconds  |
| `decay_time`    | `real(dp)` | Decay duration in seconds   |
| `sustain_level` | `real(dp)` | Sustain amplitude (0.0–1.0) |
| `release_time`  | `real(dp)` | Release duration in seconds |
| `sample_rate`   | `real(dp)` | Samples per second          |

These parameters define the **shape** of the envelope.



### Internal State (Private Memory)

| Field           | Type       | Description              |
| --------------- | ---------- | ------------------------ |
| `state`         | `integer`  | Current ADSR state       |
| `current_level` | `real(dp)` | Current output amplitude |

These fields evolve over time and should not be manipulated directly.



### Type-Bound Procedures

| Procedure          | Description                                         |
| ------------------ | --------------------------------------------------- |
| `get_next_level()` | Advance envelope by one sample and return amplitude |
| `note_on()`        | Trigger attack phase                                |
| `note_off()`       | Trigger release phase                               |



## Constructor: `adsr_t(...)`

```fortran
adsr = adsr_t(a, d, s, r, rate)
```

### Arguments

| Argument | Meaning                 |
| -------- | ----------------------- |
| `a`      | Attack time (seconds)   |
| `d`      | Decay time (seconds)    |
| `s`      | Sustain level (0.0–1.0) |
| `r`      | Release time (seconds)  |
| `rate`   | Sample rate (Hz)        |

### Behavior

* Initializes envelope parameters
* Sets initial state to `IDLE`
* Sets `current_level` to `0.0`



## Methods

### `note_on`

```fortran
call adsr%note_on()
```

**Effect**

* Forces the envelope into the `ATTACK` state
* Does not reset `current_level`

This allows retriggering from non-zero levels, mimicking analog envelope behavior.



### `note_off`

```fortran
call adsr%note_off()
```

**Effect**

* Forces the envelope into the `RELEASE` state
* Release always proceeds toward zero



### `get_next_level`

```fortran
level = adsr%get_next_level()
```

**Purpose**
Advances the envelope by **exactly one sample** and returns the resulting amplitude.



## Envelope Logic (Per State)

### IDLE

* Output forced to `0.0`
* No progression occurs



### ATTACK

* Linear rise toward `1.0`
* Step size:

```text
step = 1.0 / (attack_time * sample_rate)
```

* Transitions to `DECAY` upon reaching `1.0`



### DECAY

* Linear fall from `1.0` to `sustain_level`
* Step size:

```text
step = (1.0 - sustain_level) / (decay_time * sample_rate)
```

* Transitions to `SUSTAIN` once sustain level is reached



### SUSTAIN

* Output held constant at `sustain_level`
* No automatic exit
* Ends only when `note_off` is called



### RELEASE

* Linear fall toward `0.0`
* Uses full-scale slope for consistency:

```text
step = 1.0 / (release_time * sample_rate)
```

* Transitions to `IDLE` at zero



## Usage Pattern

Typical real-time usage inside an audio loop:

```fortran
call env%note_on()

do i = 1, num_samples
    output(i) = input(i) * env%get_next_level()
end do

call env%note_off()
```



## Design Notes



* The envelope is strictly linear in all segments
* Time constants are sample-rate invariant
* State transitions are explicit and deterministic
* This design is ideal for learning, clarity, and correctness
* For musical realism, exponential curves or time-constant smoothing may be preferable
* The explicit FSM makes later extensions trivial (velocity scaling, curve shaping, retrigger modes)



## Summary

`mod_adsr` is a clean, minimal, and correct ADSR envelope generator:

* Easy to reason about
* Efficient enough for real-time use
* Extensible without architectural regret


