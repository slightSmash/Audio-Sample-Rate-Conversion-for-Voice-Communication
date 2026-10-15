# Audio Sample-Rate Conversion for Voice Communication

A **Digital Signal Processing (DSP) mini-project** implemented in MATLAB to study and compare audio sample-rate conversion techniques for voice communication.

The project evaluates different interpolation and filtering methods based on signal quality, spectral distortion, and computational execution time.

## Overview

Sample-rate conversion is an important operation in digital audio systems and voice communication. It allows an audio signal recorded or processed at one sampling frequency to be converted to another sampling frequency.

However, changing the sampling rate can introduce aliasing, spectral distortion, and reconstruction errors if the conversion is not performed correctly.

This project implements and compares multiple sample-rate conversion approaches to understand their performance under different conversion ratios.

## Objectives

- Understand the principles of audio sample-rate conversion.
- Implement rational sample-rate conversion for different sampling-rate ratios.
- Compare interpolation and digital filtering techniques.
- Evaluate signal quality and spectral distortion.
- Measure and compare execution time.
- Study the trade-off between computational cost and signal reconstruction quality.

## Techniques Compared

| Method | Description |
|---|---|
| Linear interpolation | Estimates intermediate samples using linear interpolation, without an anti-aliasing filter. |
| Kaiser-window FIR (K = 4) | Uses a Kaiser-window-based FIR filter with a lower filter-order setting. |
| Kaiser-window FIR (K = 10) | Evaluates a Kaiser-window FIR configuration with a higher setting. |
| Kaiser-window FIR (K = 30) | Evaluates a longer Kaiser-window FIR configuration for improved filtering performance. |
| Equiripple FIR (K = 10) | Uses an equiripple FIR filter designed to control passband and stopband deviations. |
| Butterworth IIR (8th order) | Uses an eighth-order Butterworth IIR filter for sample-rate conversion. |
| MATLAB `resample` | Uses MATLAB's built-in resampling function as a reference for comparison. |

**Note:** The parameter `K` follows the implementation used in this project. Its exact relationship to filter order or length should be interpreted according to the MATLAB source code.

## Sample-Rate Conversion Ratios

The project evaluates the following conversion ratios:

| Conversion ratio | Example input sampling rate | Example output sampling rate |
|---|---:|---:|
| 1/2 | 16 kHz | 8 kHz |
| 3/4 | 16 kHz | 12 kHz |
| 3/2 | 16 kHz | 24 kHz |
| 2/1 | 16 kHz | 32 kHz |
| 3/1 | 16 kHz | 48 kHz |

These ratios cover both **downsampling** and **upsampling** scenarios.

> The sampling rates above describe the example conversion setup. Refer to the MATLAB script for the exact input signal, conversion parameters, and implementation details.

## Evaluation Metrics

The methods are compared using the following metrics.

### 1. Signal-to-Noise Ratio (SNR)

SNR measures the relationship between the desired reference signal and the error introduced by processing. A higher SNR generally indicates lower reconstruction error.

### 2. In-Band SNR

In-band SNR evaluates signal quality within the frequency band of interest. It is useful when the primary concern is preserving the frequencies relevant to voice communication.

### 3. Log-Spectral Distortion (LSD)

LSD measures differences between the reference and processed signals in the spectral domain. Lower LSD generally indicates better spectral similarity.

### 4. Execution Time

Execution time measures the computational cost of each method. It helps compare the trade-off between processing speed and signal quality.

## Results and Observations

The MATLAB implementation produces numerical results for the tested conversion ratios and methods.

The results can be used to investigate:

- How interpolation performs without anti-aliasing filtering.
- How different Kaiser-window FIR configurations affect signal quality and runtime.
- How equiripple FIR and Butterworth IIR filtering compare with other approaches.
- How custom implementations compare with MATLAB's built-in `resample` function.
- How computational cost changes with the conversion ratio and filter configuration.

The observed performance depends on the input audio, filter design, conversion ratio, and implementation. Therefore, conclusions should be drawn from the measured output rather than assuming one method is best in every situation.

**Important:** Verify unusual results, such as infinite SNR or zero spectral distortion, before interpreting them as perfect reconstruction. These values can sometimes arise from reference-signal alignment, metric implementation, or numerical edge cases.

## Project Structure

A suggested repository structure is:

```text
audio-sample-rate-conversion-dsp/
├── README.md
├── src/
│   └── sample_rate_conversion.m
├── results/
│   ├── comparison_results.csv
│   └── figures/
│       ├── snr_comparison.png
│       ├── lsd_comparison.png
│       └── runtime_comparison.png
├── report/
│   └── DSP_Sample_Rate_Conversion_Mini_Project_Report.pdf
└── LICENSE
```

Adjust the filenames and folders to match the files actually included in your repository. The structure above is a suggested organization, not a list of files guaranteed to exist.

## Requirements

- MATLAB
- MATLAB Signal Processing Toolbox, if required by the functions used in the script
- An input audio signal compatible with the implementation

## How to Run

1. Clone or download this repository.
2. Open MATLAB.
3. Navigate to the project directory.
4. Open the main MATLAB script.
5. Check that the input audio file and required dependencies are available.
6. Run the script.
7. Review the command-window output and generated figures, if applicable.

Example Git command:

```bash
git clone https://github.com/<your-username>/audio-sample-rate-conversion-dsp.git
cd audio-sample-rate-conversion-dsp
```

Replace `<your-username>` with your GitHub username.

## Applications

Sample-rate conversion is useful in:

- Voice communication systems
- Digital audio processing
- Audio playback and recording
- Speech-processing pipelines
- Multimedia systems
- Interoperability between audio systems using different sampling rates

## Future Improvements

- Add objective speech-quality metrics.
- Automate the generation of comparison plots.
- Export numerical results to CSV files.
- Test with multiple voice recordings and input sampling rates.
- Compare filter length, computational complexity, and processing delay.
- Explore real-time sample-rate conversion.
- Add a simple interface for selecting conversion ratios and filter methods.

## References

1. MathWorks, **`resample` — Resample uniform or nonuniform data**.  
   https://www.mathworks.com/help/signal/ref/resample.html

2. MathWorks, **`upfirdn` — Upsample, FIR filter, and downsample**.  
   https://www.mathworks.com/help/signal/ref/upfirdn.html

3. MathWorks, **`fir1` — Window-based FIR filter design**.  
   https://in.mathworks.com/help/signal/ref/fir1.html

4. Crochiere, R. E., and Rabiner, L. R., *Multirate Digital Signal Processing*. Prentice-Hall, 1983.

## Academic Context

Developed as a mini-project for **Digital Signal Processing (DSP)**.

**Institution:** DES Pune University, Pune  
**Academic Year:** 2026–2027

## License

Choose a license before distributing the project publicly. For example, the MIT License permits reuse and modification subject to its terms. Add a `LICENSE` file if you choose to use it.

---

*If you find this project useful for learning digital signal processing, consider starring the repository.*
