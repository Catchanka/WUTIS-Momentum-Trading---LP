# WUTIS Momentum Trading Strategy

This repository contains a replication of the intraday momentum strategy from:

**Swiss Finance Institute Research Paper Series N°24-97**  
**Beat the Market: An Effective Intraday Momentum Strategy for S&P500 ETF (SPY)**

The project first recreates the published SPY momentum strategy and then introduces an original RSP breadth veto designed to improve out-of-sample robustness.

## Repository Structure

The repository contains two main folders:

### Main

Contains the final strategy implementation, RSP extension, hypothesis testing, and supporting functions.

The files should be run in the following order:

1. `Data.m`

   Downloads or loads the required SPY and RSP market data.

   This includes:
   - SPY intraday data
   - SPY daily data
   - SPY dividends
   - RSP intraday data

2. `Key_Variables.m`

   Constructs the variables required by the original paper strategy.

   This includes:
   - trading days and intraday timestamps
   - VWAP
   - movement from the market open
   - rolling SPY volatility
   - 14-day Noise Area estimates
   - dividend adjustments

3. `Backtest.m`

   Runs the replicated paper strategy using the variables created above.

   The backtest includes:
   - Noise Area breakout signals
   - VWAP confirmation
   - 30-minute trading decisions
   - volatility-targeted position sizing
   - commissions and slippage
   - daily strategy returns and AUM

4. `Results_Benchmark.m`

   Evaluates the baseline strategy.

   Outputs include:
   - equity curve
   - train/test comparison
   - annualized return
   - annualized volatility
   - Sharpe ratio
   - drawdown and other performance statistics
   - comparison with SPY

5. `Key_Variables_RSP.m`

   Creates the additional variables required for the RSP breadth extension.

   RSP is used as an equal-weighted S&P 500 breadth measure.

6. `Backtest_RSP_Veto.m`

   Runs the final RSP Veto strategy.

   The original SPY signal remains unchanged. RSP is only used to reject a new trade when equal-weight breadth clearly contradicts the SPY signal.

   - A long SPY signal is vetoed when RSP is below both its VWAP and daily open.
   - A short SPY signal is vetoed when RSP is above both its VWAP and daily open.

7. `Results_RSP.m`

   Compares the RSP Veto strategy with the original paper strategy and SPY using the same train/test split and transaction cost assumptions.

8. `RSP_Hypothesis.m`

   Tests the economic motivation behind the RSP Veto.

   The analysis examines:
   - frequency of SPY/RSP disagreement
   - magnitude of SPY/RSP divergence
   - 30-minute forward returns after agreement and disagreement signals
   - return distributions of those signals
   - performance on days when the veto activates

## Supporting Functions

Several MATLAB functions are used by the scripts above and do not need to be run manually.

Examples include:

- `v_wap.m`
- `Rolling_Mean.m`
- `lag_TS.m`
- Alpaca data download functions

These functions are called automatically by the main scripts.

## Test Environment

The `Test Environment` folder contains alternative specifications and exploratory versions that were tested during strategy development.

These files are not required to reproduce the final results.

For example, the first RSP implementation required full RSP confirmation of every SPY trade. This was eventually replaced by the less restrictive RSP Veto used in the final model.

## Train / Test Split

The available dataset covers 2016 to 2026.

- **Training period:** January 2016 to April 2024
- **Testing period:** May 2024 to September 2026

The post-paper period is kept separate to evaluate the strategy out of sample.
