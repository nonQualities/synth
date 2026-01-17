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


# Mathematical Specification of a Linear ADSR Envelope Generator

## 1. Scope and Intent

This document specifies the mathematical model underlying a linear ADSR (Attack–Decay–Sustain–Release) envelope generator implemented in discrete time. The description is independent of any programming language or implementation detail and formalizes the envelope as a deterministic dynamical system.

All quantities are defined explicitly. Assumptions are stated directly. No perceptual or musical claims are made beyond what follows from the mathematics.

---

## 2. Discrete-Time Framework

Let the system operate at a fixed sample rate

$$
f_s \in \mathbb{R}^+, \quad f_s > 0
$$

with discrete time index

$$
n \in \mathbb{Z}_{\ge 0}
$$

The envelope is defined as a real-valued sequence

$$
e[n] \in [0, 1]
$$

updated once per sample.

Time parameters expressed in seconds are converted to sample counts by multiplication with $f_s$.

---

## 3. State Space Definition

The envelope is governed by a finite set of control states:

$$
\Sigma = \{\text{IDLE}, \text{ATTACK}, \text{DECAY}, \text{SUSTAIN}, \text{RELEASE}\}
$$

Let

$$
\sigma[n] \in \Sigma
$$

denote the active state at sample $n$.

The system state at time $n$ is therefore the ordered pair

$$
(e[n], \sigma[n])
$$

The system evolution is fully determined by this state and external control events (`note_on`, `note_off`).

---

## 4. Parameterization

The envelope is parameterized by the following real-valued constants:

- Attack time: $T_A > 0$
- Decay time: $T_D > 0$
- Sustain level: $S \in [0, 1]$
- Release time: $T_R > 0$

Associated sample counts are defined as:

$$
N_A = T_A f_s,\quad
N_D = T_D f_s,\quad
N_R = T_R f_s
$$

---

## 5. Piecewise Linear Dynamics

### 5.1 IDLE State

In the IDLE state, the envelope output is defined as:

$$
e[n] = 0
$$

No accumulation occurs. The state persists until an external transition is applied.

---

### 5.2 ATTACK State

The ATTACK state implements a linear increase toward unity.

The slope is defined as:

$$
\Delta_A = \frac{1}{T_A f_s}
$$

The recurrence relation is:

$$
e[n+1] = e[n] + \Delta_A
$$

The transition condition is:

$$
e[n+1] \ge 1 \Rightarrow
\begin{cases}
e[n+1] = 1 \\
\sigma[n+1] = \text{DECAY}
\end{cases}
$$

This defines a bounded linear ramp.

---

### 5.3 DECAY State

The DECAY state implements a linear decrease from unity to the sustain level.

The slope is defined as:

$$
\Delta_D = \frac{1 - S}{T_D f_s}
$$

The recurrence relation is:

$$
e[n+1] = e[n] - \Delta_D
$$

The transition condition is:

$$
e[n+1] \le S \Rightarrow
\begin{cases}
e[n+1] = S \\
\sigma[n+1] = \text{SUSTAIN}
\end{cases}
$$

---

### 5.4 SUSTAIN State

The SUSTAIN state is defined as a fixed point:

$$
e[n] = S \quad \forall n \text{ such that } \sigma[n] = \text{SUSTAIN}
$$

No internal time evolution occurs in this state. Exit is possible only via an external transition.

---

### 5.5 RELEASE State

The RELEASE state implements a linear decrease toward zero.

The slope is defined independently of the current envelope level:

$$
\Delta_R = \frac{1}{T_R f_s}
$$

The recurrence relation is:

$$
e[n+1] = e[n] - \Delta_R
$$

The transition condition is:

$$
e[n+1] \le 0 \Rightarrow
\begin{cases}
e[n+1] = 0 \\
\sigma[n+1] = \text{IDLE}
\end{cases}
$$

This enforces a constant slope rather than a constant-duration release.

---

## 6. Global System Definition

The envelope evolution may be expressed compactly as:

$$
e[n+1] =
\begin{cases}
0 & \sigma[n] = \text{IDLE} \\
e[n] + \frac{1}{T_A f_s} & \sigma[n] = \text{ATTACK} \\
e[n] - \frac{1 - S}{T_D f_s} & \sigma[n] = \text{DECAY} \\
S & \sigma[n] = \text{SUSTAIN} \\
e[n] - \frac{1}{T_R f_s} & \sigma[n] = \text{RELEASE}
\end{cases}
$$

subject to the constraint:

$$
0 \le e[n] \le 1
$$

---

## 7. Relation to Continuous-Time Models

Each dynamic segment corresponds to the discrete-time forward Euler integration of a first-order differential equation with constant derivative:

Attack:
$\frac{de}{dt} = \frac{1}{T_A}$

Decay:
$\frac{de}{dt} = -\frac{1 - S}{T_D}$

Release:
$\frac{de}{dt} = -\frac{1}{T_R}$

The discretization is explicit and stable under ideal arithmetic.

---

## 8. Stability and Boundedness

The system satisfies the following properties:

- Envelope output remains bounded in $[0,1]$
- Slopes are finite and constant within each state
- The system is numerically stable under finite-precision arithmetic
- Time scaling is invariant with respect to sample rate

---

## 9. Formal Interpretation

The ADSR envelope constitutes a deterministic hybrid system composed of:

- A finite-state controller
- A continuous-valued state variable
- Linear recurrence relations
- Event-driven transitions

The system is fully observable and deterministic.

---

## 10. Conclusion

The linear ADSR envelope is a piecewise-defined, discrete-time linear dynamical system with explicit state transitions and bounded output. Its behavior is fully determined by its parameters, the sampling rate, and external control events.

No nonlinearities, implicit time constants, or higher-order memory effects are present. The system is mathematically simple, stable, and analytically tractable.
