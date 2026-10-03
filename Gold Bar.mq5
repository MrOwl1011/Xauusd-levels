#property copyright "Copyright 2025, Zaid Elamshaaly Mr. Owl"
#property link      "https://www.instagram.com/coding_xaid/"
#property version   "15.7"


#property strict
#include <Trade\Trade.mqh>
CTrade trade;
input group "Welcome to Golden Bar "
//=======================Lot Calculation==============================================//
input group "Lot Size Configuration"
input bool UseDynamicLotSize = false; // Switch to DynamicLotSize 
double FixedLotSize ;
double FixedLotSizeLow = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY)*0.0001,2);
double FixedLotSizeMidLow = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY)*0.0002,2);
double FixedLotSizeMid = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY)*0.0005,2);
double FixedLotSizeMidHIGHT = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY)*0.0008,2);
double FixedLotSizeHigh = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY)*0.001,2);
double FixedLotSizeSuperHigh = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY)*0.0015,2);
enum ENUM_RISK_LEVEL
{
   RISK_LOW,       // Low Risk
   RISK_MEDIUM_LOW,    // Medium Low Risk
   RISK_MEDIUM,    // Medium Risk
   RISK_MEDIUM_HIGH,    // Medium High Risk
   RISK_HIGH,       // High Risk
   RISK_SUPER_HIGH,    // Super High Risk
};
input ENUM_RISK_LEVEL RiskLevel = RISK_MEDIUM;               // Risk Level

//=======================ENTRY FILTERS==============================================//
input group "Entry Filters (turn each rule on/off)"
input bool UseADXFilter     = true;    // ADX strength filter
input int  ADXPeriod        = 14;      // ADX period
input double ADXMinLevel    = 30.0;    // ADX must be above this
input bool UseDIFilter      = true;    // +DI/-DI direction filter
input bool UseSMAFilter     = true;    // Price vs SMA filter (M1)
input int  FastSMAPeriod    = 45;      // Fast SMA period
input int  SlowSMAPeriod    = 150;     // Slow SMA period
input bool UseRatioFilter   = true;    // Good-ratio filter (close near level)
input double GoodRatioInput = 4.8;     // Good ratio value
input bool UseSessionFilter = true;    // Trading session filter
input int  Session1StartHour = 11;     // Session 1 start (server hour)
input int  Session1EndHour   = 17;     // Session 1 end (server hour)
input int  Session2StartHour = 2;      // Session 2 start (server hour)
input int  Session2EndHour   = 5;      // Session 2 end (server hour)

//=======================COLORS==============================================//
#define NEON_PINK       C'255,20,147'    // Deep Pink (Hot Neon)  
#define NEON_BLUE       C'0,255,255'     // Cyan (Electric Blue)  
#define NEON_PURPLE     C'180,20,255'    // Bright Purple  
#define NEON_YELLOW     C'255,255,0'     // Pure Yellow  
#define NEON_ORANGE     C'255,95,31'     // Vivid Orange  
#define NEON_RED        C'255,0,100'     // Bright Pink-Red  
#define NEON_TEAL       C'0,255,200'     // Glowing Teal  
#define NEON_LIME       C'190,255,0'     // Acid Green  
#define NEON_MAGENTA    C'255,0,255'     // Electric Magenta  
#define NEON_CYAN       C'0,255,255'     // Pure Cyan (Same as NEON_BLUE)  
#define NEON_CORAL      C'255,95,85'     // Neon Coral  
#define NEON_LAVENDER   C'200,160,255'   // Pastel Purple  
#define NEON_MINT       C'50,255,150'    // Bright Mint  
#define NEON_GOLD       C'255,215,0'     // Metallic Gold  
#define NEON_SKY        C'100,200,255'   // Sky Blue Glow  
//=======================LEVELS==============================================//
double MainLevel ;
int LevelsCount = 50;   // main levels above AND below MainLevel
color MainLineColor = NEON_SKY;
color MinorLineColor = NEON_GOLD;
//========================Main==============================================//

double GoodRatio = GoodRatioInput;
int adxHandle = INVALID_HANDLE;   // ADX indicator handle (created once in OnInit)

double sls = 5;
double tps = 50;
//=========================================================================//
double Step = 10.0;
double MinorStep = 5.0;
double previousMainLevel = 0.0;
double lastCrossedLevel = 0.0;
bool signalTriggered = false;
datetime signalTime;
bool crossedLevels[100];

int maHandle;          // Handle for the Moving Average indicator
double maBuffer[];     // Array to store MA values
int maHandle2;          // Handle for the Moving Average indicator
double maBuffer2[];     // Array to store MA values

bool isBull = false;
bool isBear = false;
CPositionInfo m_position;


//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   static int macdHandle = INVALID_HANDLE;
   ArrayInitialize(crossedLevels, false);
   Comment("Golden Bar By Zaid Github MrOwl1011");
   // Grid is drawn from OnTick via CheckForNewWeekSimple() on the first tick
   

    
    //---------------------------------------------------------------
         // Create Moving Average indicator
    maHandle = iMA(_Symbol, PERIOD_M1, FastSMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
    maHandle2 = iMA(_Symbol, PERIOD_M1, SlowSMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
    adxHandle = iADX(_Symbol, _Period, ADXPeriod);
    if(adxHandle == INVALID_HANDLE)
    {
        Print("Failed to create ADX indicator");
        return(INIT_FAILED);
    }
    
    if(maHandle == INVALID_HANDLE)
    {
        Print("Failed to create Moving Average indicator");
        return(INIT_FAILED);
    }
    
    // Set the buffer as series (newest data at index 0)
    ArraySetAsSeries(maBuffer2, true);
        if(maHandle2 == INVALID_HANDLE)
    {
        Print("Failed to create Moving Average indicator");
        return(INIT_FAILED);
    }
    
    // Set the buffer as series (newest data at index 0)
    ArraySetAsSeries(maBuffer2, true);
    
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Clean Up in OnDeinit()-------------------------------------------EMA                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(maHandle != INVALID_HANDLE)
    {
        IndicatorRelease(maHandle);
    }
    if(maHandle2 != INVALID_HANDLE)
    {
        IndicatorRelease(maHandle2);
    }
    if(adxHandle != INVALID_HANDLE)
    {
        IndicatorRelease(adxHandle);
    }
}

//+------------------------------------------------------------------+
//| Draw Horizontal Lines                                            |
//+------------------------------------------------------------------+
void DrawLevels()
{
   ObjectsDeleteAll(0, "Main Level ");
   ObjectsDeleteAll(0, "Minor Level ");

   // LevelsCount main levels above and below MainLevel, minors between each pair
   for (int i = -LevelsCount; i <= LevelsCount; i++)
   {
      double mainLevel = MainLevel + i * Step;
      string mainName = "Main Level " + (string)i;
      ObjectCreate(0, mainName, OBJ_HLINE, 0, 0, mainLevel);
      ObjectSetInteger(0, mainName, OBJPROP_COLOR, MainLineColor);
      if (i == 0)
         ObjectSetInteger(0, mainName, OBJPROP_WIDTH, 2);

      if (i == LevelsCount)
         break;

      int m = 0;
      for (double minorLevel = mainLevel + MinorStep; minorLevel < mainLevel + Step - 0.0001; minorLevel += MinorStep)
      {
         string minorName = "Minor Level " + (string)i + "_" + (string)m++;
         ObjectCreate(0, minorName, OBJ_HLINE, 0, 0, minorLevel);
         ObjectSetInteger(0, minorName, OBJPROP_COLOR, MinorLineColor);
      }
   }
}

//+------------------------------------------------------------------+
//| ADX Strength Check Function (MQL5)                               |
//| Returns TRUE if ADX > 25 (strong trend)                          |
//+------------------------------------------------------------------+
bool IsADXStrong()
{
   // Get ADX, +DI, and -DI values
   double adxArray[], plusDIArray[], minusDIArray[];

   // Copy latest values (shift=0 = current candle)
   if(CopyBuffer(adxHandle, 0, 0, 1, adxArray) != 1 ||        // MODE_MAIN (ADX)
      CopyBuffer(adxHandle, 1, 0, 1, plusDIArray) != 1 ||     // MODE_PLUSDI (+DI)
      CopyBuffer(adxHandle, 2, 0, 1, minusDIArray) != 1)      // MODE_MINUSDI (-DI)
   {
      isBull = false;
      isBear = false;
      return false;
   }

   // Check if ADX is above the configured level
   bool isStrongTrend = (adxArray[0] > ADXMinLevel);
   
   // Optional: Add +DI/-DI direction filter
   isBull = (plusDIArray[0] > minusDIArray[0]);
   isBear = (plusDIArray[0] < minusDIArray[0]);
   
   return isStrongTrend;
}
//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
{ 

   // Redraw the grid at every week start (and once when the EA loads)
   if (CheckForNewWeekSimple())
   {
      previousMainLevel = MainLevel;
      ArrayInitialize(crossedLevels, false);
      lastCrossedLevel = 0.0;
      signalTriggered = false;
      DrawLevels();
   }

   for (int i = -LevelsCount; i <= LevelsCount; i++)
   {
      double currentLevel = MainLevel + i * Step;

      if ((lastCrossedLevel < currentLevel && iClose(_Symbol,_Period,0) >= currentLevel) ||
          (lastCrossedLevel > currentLevel && iClose(_Symbol,_Period,0) <= currentLevel))
      {
         if (lastCrossedLevel != currentLevel)
         {
            string arrowName = "Arrow_Level_" + (string)i;
            ObjectCreate(0, arrowName, OBJ_ARROW, 0, iTime(_Symbol,_Period,0), iClose(_Symbol,_Period,0));
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);

            signalTriggered = true;
            signalTime = iTime(_Symbol,_Period,0);
            lastCrossedLevel = currentLevel;
            break;
         }
      }
   }
   if (signalTriggered && iTime(_Symbol,_Period,0) > signalTime)
   {
      double closePrice = iClose(_Symbol,_Period,1);

      string tradeSignal = (closePrice > lastCrossedLevel) ? "Sell Gold" : "Buy Gold";

      string alertMessageB = StringFormat("test 3.6 %s \nEP: %.2f$ / TP:%.2f / SL:%.2f / Entry: %.2f",
                                          tradeSignal, (lastCrossedLevel + 5) - closePrice, lastCrossedLevel + 5, lastCrossedLevel - 5, lastCrossedLevel);
      string alertMessageS = StringFormat("test 3.6 %s \nEP: %.2f$ / TP:%.2f / SL:%.2f / Entry: %.2f",
                                          tradeSignal, closePrice - (lastCrossedLevel - 5), lastCrossedLevel - 5, lastCrossedLevel + 5, lastCrossedLevel);
      double BuyGoodRatio  = (lastCrossedLevel + 5) - closePrice;
      double SellGoodRatio  = closePrice - (lastCrossedLevel - 5);
         
      
      bool adxOk = IsADXStrong();   // also refreshes isBull / isBear
      adxOk = !UseADXFilter || adxOk;

      if (tradeSignal == "Sell Gold" && adxOk
          && (!UseSMAFilter || SellSma())
          && (!UseDIFilter || isBear)
          && (!UseRatioFilter || BuyGoodRatio >= GoodRatio))
      {
         OpenSellOrder();

         Comment(alertMessageS);
      }
      else if (tradeSignal == "Buy Gold" && adxOk
          && (!UseSMAFilter || BuySma())
          && (!UseDIFilter || isBull)
          && (!UseRatioFilter || SellGoodRatio >= GoodRatio))
      {
         OpenBuyOrder();

         Comment(alertMessageB);
      }

      signalTriggered = false;
   }
  // CheckBreakEven();
   TrailingStop();
   

}

//+------------------------------------------------------------------+
//|                  Start value depends on weekly open              |
//+------------------------------------------------------------------+

double WeeklyValue()
{

      int Start = (iOpen(_Symbol,PERIOD_W1,1)-140)/10; 
      string StringStart = IntegerToString(Start) + DoubleToString(3.6, 1); 
      double Final = StringToDouble(StringStart); 
      
   return Final;

}

//+------------------------------------------------------------------+
//| Buy Order                                                        |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{

   
   if ( IsGoodTradingSession()) {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = lastCrossedLevel - sls;
   double tp = lastCrossedLevel + tps;
   double LotSize = CalculateLotSize();
   if (!trade.Buy(LotSize, _Symbol, price, sl, tp, "Buy Order"))
      Print("Buy order failed: ", GetLastError());
      }
}

//+------------------------------------------------------------------+
//| Sell Order                                                       |
//+------------------------------------------------------------------+
void OpenSellOrder()
{ 

   if ( IsGoodTradingSession()) {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = lastCrossedLevel + sls;
   double tp = lastCrossedLevel - tps;
   double LotSize = CalculateLotSize();
   if (!trade.Sell(LotSize, _Symbol, price, sl, tp, "Sell Order"))
      Print("Sell order failed: ", GetLastError());
      }
}


//+------------------------------------------------------------------+
//| SMA BUY ---------------------------------------------------------|
//+------------------------------------------------------------------+
bool BuySma()
{
    // Get current price
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Get MA values
    if(CopyBuffer(maHandle, 0, 0, 1, maBuffer) != 1)
    {
        Print("Failed to copy MA buffer");
        return false;
    }
    
    double currentMA = maBuffer[0];
    
        if(CopyBuffer(maHandle2, 0, 0, 1, maBuffer2) != 1)
    {
        Print("Failed to copy MA buffer");
        return false;
    }
    
    double currentMA2 = maBuffer2[0];
    // Check if price is above MA
    return (currentPrice > currentMA && currentPrice > currentMA2);
}

//+------------------------------------------------------------------+
//| SMA SELL --------------------------------------------------------|
//+------------------------------------------------------------------+
bool SellSma()
{
    // Get current price
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Get MA values
    if(CopyBuffer(maHandle, 0, 0, 1, maBuffer) != 1)
    {
        Print("Failed to copy MA buffer");
        return false;
    }
    
    double currentMA = maBuffer[0];
     if(CopyBuffer(maHandle2, 0, 0, 1, maBuffer2) != 1)
    {
        Print("Failed to copy MA buffer");
        return false;
    }
    
    double currentMA2 = maBuffer2[0];
    // Check if price is above MA
    return (currentPrice < currentMA && currentPrice < currentMA2 );
}

//+------------------------------------------------------------------+
//| Trailing Stop Logic (Modified to work with break-even)           |
//+------------------------------------------------------------------+
void TrailingStop()
{
    for(int i = PositionsTotal()-1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            // Skip positions that have hit break-even
            if(StringFind(PositionGetString(POSITION_COMMENT), "BE_ACTIVATED") >= 0)
                continue;
                
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSl = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY 
                               ? SymbolInfoDouble(_Symbol, SYMBOL_BID) 
                               : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double profitPoints = MathAbs(currentPrice - openPrice) / _Point;

            // Only trail if profit reaches threshold
            if(profitPoints >= 5000)
            {
                double newSl = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                            ? currentPrice - 2000 * _Point
                            : currentPrice + 2000 * _Point;

                // Only modify if we're making the stop loss better
                if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && newSl > currentSl) ||
                   (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && newSl < currentSl))
                {
                    if(!trade.PositionModify(ticket, newSl, PositionGetDouble(POSITION_TP)))
                    {
                        Print("Failed to trail stop for #", ticket, 
                              " Error:", GetLastError());
                    }
                }
            }
        }
    }
}

//-------------------------------------------------------
//             Trading Sessions                          |
//-------------------------------------------------------
// Only trade during active market hours
bool IsGoodTradingSession()
{
    if(!UseSessionFilter)
        return true;

    MqlDateTime timeNow;
    TimeCurrent(timeNow);

    if(timeNow.hour >= Session1StartHour && timeNow.hour < Session1EndHour)
        return true;
    if(timeNow.hour >= Session2StartHour && timeNow.hour < Session2EndHour)
        return true;

        
    return false;
}

//+------------------------------------------------------------------+
//| Simple week detection                                            |
//+------------------------------------------------------------------+
datetime currentWeekStart = 0;

// Returns true once at EA start and again at every new weekly bar
bool CheckForNewWeekSimple()
{
    datetime weekStart = iTime(_Symbol, PERIOD_W1, 0);
    if(weekStart == 0 || weekStart == currentWeekStart)
        return false;

    Print("NEW WEEK! Week start: ", TimeToString(weekStart));
    currentWeekStart = weekStart;
    MainLevel = WeeklyValue();
    Comment("The level is : ", MainLevel);
    return true;
}

//+-----------------------------------------------------------------+
//|                       Lot size calculation                       |
//+-----------------------------------------------------------------+
double CalculateLotSize()
{
    if(!UseDynamicLotSize)
    {
    switch(RiskLevel)
     {
      case  RISK_LOW: FixedLotSizeLow;
       return FixedLotSizeLow;
        break;
        case  RISK_MEDIUM_LOW: FixedLotSizeMidLow;
       return FixedLotSizeMidLow;
        break;

       case RISK_MEDIUM:
       return FixedLotSizeMid;
        break;
        case  RISK_MEDIUM_HIGH: FixedLotSizeMidHIGHT;
       return FixedLotSizeMidHIGHT;
        break;
     case RISK_HIGH:
      return FixedLotSizeHigh;
     break;
     case RISK_SUPER_HIGH:
      return FixedLotSizeSuperHigh;
     break;
    ; 
        break;
     }
     
        return FixedLotSizeLow;
    }
    else
    {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double LotSize;
   
       switch(RiskLevel)
     {
      case  RISK_LOW: return NormalizeDouble(equity*0.0001, 2);
       return LotSize;
        break;
      case RISK_MEDIUM_LOW:
       return NormalizeDouble(equity*0.0002, 2);
      return LotSize;
        break;
     case RISK_MEDIUM:
      return NormalizeDouble(equity*0.0005, 2);
     return LotSize;
      break;
     case RISK_MEDIUM_HIGH:
      return NormalizeDouble(equity*0.0008, 2);
     return LotSize;
      break;
        case RISK_HIGH:
      return NormalizeDouble(equity*0.001, 2);
     return LotSize;
      break;
       case RISK_SUPER_HIGH:
      return NormalizeDouble(equity*0.003, 2);
     return LotSize;
      break;
     }
    
        return LotSize;
    }
}






