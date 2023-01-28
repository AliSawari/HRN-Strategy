#property copyright "Created By Ali Sawari"
#property version   "1.00"
#property description ""

#include <stdlib.mqh>
#include <stderror.mqh>

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 1

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy Hammer-8"

//--- indicator buffers
double Buffer1[];

datetime time_alert; //used when sending alert
extern bool Audible_Alerts = true;
extern bool Push_Notifications = true;
double myPoint; //initialized in OnInit

void myAlert(string type, string message)
  {
   int handle;
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | Buy Hammer-8 MT4 @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
   else if(type == "indicator")
     {
      Print(type+" | Buy Hammer-8 MT4 @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Audible_Alerts) Alert(type+" | Buy Hammer-8 MT4 @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      handle = FileOpen("Buy Hammer-8 MT4.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
      if(handle != INVALID_HANDLE)
        {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, type+" | Buy Hammer-8 MT4 @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
         FileClose(handle);
        }
      if(Push_Notifications) SendNotification(type+" | Buy Hammer-8 MT4 @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   IndicatorBuffers(1);
   SetIndexBuffer(0, Buffer1);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexArrow(0, 241);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
     }
   else
      limit++;
   
   //--- main loop
   for(int i = limit-1; i >= 0; i--) {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      float MA8_1 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+1);
      float MA8_2 = iMA(NULL, PERIOD_CURRENT, 8, 0, MODE_SMA, PRICE_CLOSE, i+2);
      float MA20_1 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+1);
      float MA20_2 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+2);
      float MA50_1 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+1);
      float MA50_2 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+2);
      //Indicator Buffer 1
      if(   
        // MA comparison in all 2 candles      
         MA8_1 > MA20_1
         && MA20_1 > MA50_1
         && MA8_2 > MA20_2
         && MA20_2 > MA50_2
         // MA increasing in all 2 candles
         && MA8_1 > MA8_2
         && MA20_1 > MA20_2
         && MA50_1 > MA50_2
      
        && Open[2+i] > Close[2+i] //Candlestick Open > Candlestick Close
        && (High[1+i] - MathMax(Open[1+i], Close[1+i]) ) <= MathAbs(Open[1+i] - Close[1+i]) //Candlestick Upper Wick <= Candlestick Body
        && ( MathMin(Open[1+i], Close[1+i]) - Low[1+i] ) >= 3 * MathAbs(Open[1+i] - Close[1+i]) //Candlestick Lower Wick >= 3 * Candlestick Body

        // last bullish candle's highest body point should close above MA8
        && MathMax(Open[1+i], Close[1+i]) > MA8_1
        
        // Hammer's Lower Shadow should be at least 60% below MA8
        && Low[1+i] + 0.6 * (MathMin(Open[1+i], Close[1+i]) - MA8_1

        // RSI below 70
         && iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 1+i) < 70
      )
        {
         Buffer1[i] = Low[1+i]; //Set indicator value at Candlestick Low
         if(i == 0 && Time[0] != time_alert) { myAlert("indicator", "Buy Hammer-8"); time_alert = Time[0]; } //Instant alert, only once per bar
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
}
