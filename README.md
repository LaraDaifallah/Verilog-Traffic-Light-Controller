# Verilog Traffic Light Controller

A seven-state Moore FSM controlling a main road, a side road, and a pedestrian crossing. Vehicle requests and pedestrian button presses are latched, pedestrian requests have priority at the service decision, and yellow/all-red phases separate conflicting traffic movements.

## Design and verification

`src/traffic.v` contains three modules:

| Module | Purpose |
| --- | --- |
| `traffic_ctrl` | RTL controller with state register, cycle timer, request latches, and Moore outputs |
| `traffic_ctrl_ref` | Reference model used for output comparison |
| `traffic_ctrl_tb` | Self-checking testbench with seven scenarios and console PASS/FAIL messages |

The active-low `rst` input initializes main green, side red, and walk off. `VS` is the side-road vehicle sensor; `PB` is the pedestrian button. Road light encodings are `001` green, `010` yellow, and `100` red.

## Timing

| Phase | Duration in clock cycles |
| --- | --- |
| Main green | At least 60 before servicing a request |
| Side green | 40 |
| Pedestrian walk | 40 |
| Yellow | 5 |
| All red | 2 |

Timing parameters are cycle counts, not physical seconds. The testbench clock has a 10 ns period. A hardware implementation needs an appropriate time base to translate these values into real traffic-light durations.

## Simulation

Use a simulator supporting SystemVerilog, because the testbench uses `string` task arguments despite the `.v` extension. With Icarus Verilog installed, run from the repository root:

```bash
mkdir -p build
iverilog -g2012 -s traffic_ctrl_tb -o build/traffic_ctrl_tb.vvp src/traffic.v
vvp build/traffic_ctrl_tb.vvp
```

Alternatively, compile `src/traffic.v` in SystemVerilog mode in your HDL simulator, select `traffic_ctrl_tb` as the simulation top, and run until `$finish`.

The existing testbench covers reset, minimum main-green time, exact side-green time, pedestrian priority, exact walk time, queued pedestrian requests during side green, and idle behavior. It compares RTL and reference outputs on falling clock edges. The supplied report records a passing run; a matching reference model does not independently prove every possible input sequence.

## Project documents

- [Project report](AvancedProj.pdf): specification, state encoding, timing, and simulation screenshots.
- [State diagram](state.pdf): supplied FSM diagram.
- `finalWave.asdb`: original simulator waveform database; open it with a compatible Aldec simulator. GitHub does not preview this binary format, and it is not needed to compile the source.

## Author

Lara Daifallah — Birzeit University, ENCS3310 Advanced Digital Design, Section 3.
