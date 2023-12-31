//+------------------------------------------------------------------+

//|                  TestExpert_v2.mq5                        |

//+------------------------------------------------------------------+

#property copyright "Copyright 2023, MetaQuotes Software Corp."

#property link "https://www.mql5.com"

#property version "1.00"

#property strict

#property indicator_separate_window

#property indicator_buffers 4

#property indicator_color1 SteelBlue

#property indicator_color2 Salmon

#property indicator_color3 Lime

#property indicator_color4 Red



// Input Parameters

input double RiskPercentage = 2.0;

input int StopLoss = 100;

input int TakeProfit = 200;

input int MACDFastEMA = 12;

input int MACDSlowEMA = 26;

input int MACDSignalSMA = 9;

input int RSIOverbought = 70;

input int RSIOversold = 30;

input int ADXPeriod = 14;

input int ATRPeriod = 14;

input int CCIPeriod = 14;

input int EMA20Period = 20;

input int EMA50Period = 50;

input int MFIPeriod = 14;

input double SARStep = 0.02;

input double SARMaximum = 0.2;

input int StochPeriod = 14;

input int StochKPeriod = 5;

input int StochDPeriod = 3;

input int WilliamsRPeriod = 14;



// Global Variables

int ticket = 0;

double lotSize = 0.01;

double accountEquity = 0.0;

int MagicNumber = 12345;



int OnInit()

{

    EventSetTimer(60);

    return (INIT_SUCCEEDED);

}



void OnDeinit(const int reason)

{

    CloseAllOrders();

}



void OnTimer()

{

    if (IsNewBar())

    {

        AnalyzeMarket();

        UpdateSLTPLevels();

        TradeDecision();

    }

}



bool IsNewBar()

{

    static datetime PrevTime = 0;

    datetime CurrTime = iTime(_Symbol, _Period, 0);

    if (PrevTime != CurrTime)

    {

        PrevTime = CurrTime;

        return (true);

    }

    return (false);

}



// Analyze the market

void AnalyzeMarket()

{

   // Calculate EMA values

   double ema20 = iMA(_Symbol, _Period, EMA20Period, 0, MODE_EMA, PRICE_CLOSE);

   double ema50 = iMA(_Symbol, _Period, EMA50Period, 0, MODE_EMA, PRICE_CLOSE);



   // Calculate other indicators' values

   double adx = iADX(_Symbol, _Period, ADXPeriod);

   double stochastic = iStochastic(_Symbol, _Period, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_MAIN);

   double cci = iCCI(_Symbol, _Period, CCIPeriod, PRICE_CLOSE);

   double williamsR = iWPR(_Symbol, _Period, WilliamsRPeriod);

   double obv = iOBV(_Symbol, _Period, OBV_MODE_MAIN);

   double chaikin = iChaikin(_Symbol, _Period, 3, 10, MODE_SMA, OBV_MODE_MAIN);

   double ad = iAD(_Symbol, _Period);

   double atr = iATR(_Symbol, _Period, ATRPeriod);

}



// Update stop loss and take profit levels

void UpdateSLTPLevels()

{

   double atr = iATR(_Symbol, _Period, ATRPeriod);

   double stopLossLevel = NormalizeDouble(Bid - StopLoss * _Point, _Digits);

   double takeProfitLevel = NormalizeDouble(Bid + TakeProfit * _Point, _Digits);



   // Modify stop loss and take profit levels of open trades

   ModifyOpenTradeSLTP(stopLossLevel, takeProfitLevel);

}



void ModifyOpenTradeSLTP(double newSL, double newTP)

{

    for (int i = 0; i < OrdersTotal(); i++)

    {

        if (OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == MagicNumber)

        {

            if (OrderType() == OP_BUY)

            {

                double bid = MarketInfo(_Symbol, MODE_BID);

                bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newTP, newSL, 0, CLR_NONE);

            }

            if (OrderType() == OP_SELL)

            {

                double ask = MarketInfo(_Symbol, MODE_ASK);

                bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newTP, newSL, 0, CLR_NONE);

            }

        }

    }

}



void TradeDecision()



{

    double lot = CalculateLotSize();



    if (IsBuySignal())

    {

        OpenBuyOrder(lot);

    }



    if (IsSellSignal())

    {

        OpenSellOrder(lot);

    }

}



void OpenBuyOrder(double lot)

{

    double sl = NormalizeDouble(Bid - iATR(_Symbol, _Period, ATRPeriod, 0) * 1.5, _Digits);

    double tp = NormalizeDouble(Bid + iATR(_Symbol, _Period, ATRPeriod, 0) * 1.5, _Digits);



    int ticket = OrderSend(_Symbol, OP_BUY, lot, MarketInfo(_Symbol, MODE_ASK), 5, sl, tp, "Long", MagicNumber);

}



void OpenSellOrder(double lot)



{

    double sl = NormalizeDouble(Bid + iATR(_Symbol, _Period, ATRPeriod, 0) * 1.5, _Digits);

    double tp = NormalizeDouble(Bid - iATR(_Symbol, _Period, ATRPeriod, 0) * 1.5, _Digits);



    int ticket = OrderSend(_Symbol, OP_SELL, lot, MarketInfo(_Symbol, MODE_BID), 5, sl, tp, "Short", MagicNumber);

}



double CalculateLotSize()

{

    double riskPct = AccountEquity() * RiskPercentage / 100;

    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);



    double atr = iATR(_Symbol, _Period, ATRPeriod, 0);



    double lot = NormalizeDouble(riskPct / (atr * tickSize / tickValue), 2);



    return (lot);

}



bool IsBuySignal()



{

    double ema20 = iMA(_Symbol, _Period, EMA20Period, 0, MODE_EMA, PRICE_CLOSE, 0);

    double ema50 = iMA(_Symbol, _Period, EMA50Period, 0, MODE_EMA, PRICE_CLOSE, 0);



    double adx = iADX(_Symbol, _Period, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 0);

    double cci = iCCI(_Symbol, _Period, CCIPeriod, PRICE_TYPICAL, 0);

    double mfi = iMFI(_Symbol, _Period, MFIPeriod, 0);

    double sar = iSAR(_Symbol, _Period, SARStep, SARMaximum);

    double stochK = iStochastic(_Symbol, _Period, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_MAIN, 0);

    double stochD = iStochastic(_Symbol, _Period, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_SIGNAL, 0);

    double williamsR = iWPR(_Symbol, _Period, WilliamsRPeriod, 0);



    if (ema20 > ema50 && adx > 20 && cci < 100 && mfi < 80 && sar < Bid && stochK < stochD && williamsR < -50)

    {

        return (true);

    }



    return (false);

}



bool IsSellSignal()



{

    double ema20 = iMA(_Symbol, _Period, EMA20Period, 0, MODE_EMA, PRICE_CLOSE, 0);

    double ema50 = iMA(_Symbol, _Period, EMA50Period, 0, MODE_EMA, PRICE_CLOSE, 0);



    double adx = iADX(_Symbol, _Period, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 0);

    double cci = iCCI(_Symbol, _Period, CCIPeriod, PRICE_TYPICAL, 0);

    double mfi = iMFI(_Symbol, _Period, MFIPeriod, 0);

    double sar = iSAR(_Symbol, _Period, SARStep, SARMaximum);

    double stochK = iStochastic(_Symbol, _Period, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_MAIN, 0);

    double stochD = iStochastic(_Symbol, _Period, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_SIGNAL, 0);

    double williamsR = iWPR(_Symbol, _Period, WilliamsRPeriod, 0);



    if (ema20 < ema50 && adx > 20 && cci > -100 && mfi > 20 && sar > Bid && stochK > stochD && williamsR > -50)

    {

        return (true);

    }



    return (false);

}



void CloseAllOrders()



{

    for (int i = OrdersTotal() - 1; i >= 0; i--)

    {

        if (OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == MagicNumber)



        {

            OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5);

        }

    }

}
