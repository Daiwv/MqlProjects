//+------------------------------------------------------------------+
//|                                       TestSimulateTranSystem.mq4 |
//|                                Copyright 2016, Chirita Alexandru |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Chirita Alexandru"
#property link      "https://www.mql5.com"
#property version   "1.20"
#property strict

#include <MyMql\System\SimulateTranSystem.mqh>
#include <stdlib.mqh>
#include <stderror.mqh>

//#property indicator_chart_window

extern bool UseKeyBoardChangeChart = true;
extern bool StartSimulationAgain = false;

static SimulateTranSystem system(DECISION_TYPE_ALL, LOT_MANAGEMENT_ALL, TRANSACTION_MANAGEMENT_ALL);

int OnInit() // start()
{
	ResetLastError();
	RefreshRates();
	ChartRedraw();
	
	if(!StringIsNullOrEmpty(CurrentSymbol) && (_Symbol != CurrentSymbol))
	{
		Sleep(20);
		GlobalContext.Config.ChangeSymbol(CurrentSymbol, PERIOD_CURRENT, UseKeyBoardChangeChart);
		Sleep(20);
		return INIT_SUCCEEDED;
	}
	
	if(FirstSymbol == NULL)
	{
		GlobalContext.Config.Initialize(true, true, false, true, __FILE__);
		
		GlobalContext.DatabaseLog.Initialize(true);
		string lastSymbol = system.GetLastSymbol();
		string currentSymbol = GlobalContext.Config.GetNextSymbol(lastSymbol);
		
		if(StringIsNullOrEmpty(lastSymbol) || (StringIsNullOrEmpty(currentSymbol) && StartSimulationAgain))
		{
			GlobalContext.DatabaseLog.ParametersSet(GlobalContext.Config.GetConfigFile());
			GlobalContext.DatabaseLog.CallWebServiceProcedure("NewTradingSession");
			Print(GlobalContext.Config.GetConfigFile());
			
			system.SetupTransactionSystem(); //_Symbol);
		}
		else if(!StringIsNullOrEmpty(currentSymbol))
		{
			system.SetupTransactionSystem();
			GlobalContext.Config.InitCurrentSymbol(currentSymbol);
			GlobalContext.Config.ChangeSymbol(currentSymbol, PERIOD_CURRENT, UseKeyBoardChangeChart);
		
			return (INIT_SUCCEEDED);
		}
		else
			return (INIT_SUCCEEDED);
	}
	
	system.TestTransactionSystemForCurrentSymbol(true, true, false);
	
	if(!GlobalContext.Config.ChangeSymbol(UseKeyBoardChangeChart))
	{
		GlobalContext.DatabaseLog.ParametersSet(GlobalContext.Config.GetConfigFile());
		GlobalContext.DatabaseLog.CallWebServiceProcedure("EndTradingSession");
		Print("Simulation finished! Job done!");
		
		GlobalContext.DatabaseLog.ParametersSet(GlobalContext.Config.GetConfigFile());
		GlobalContext.DatabaseLog.CallWebServiceProcedure("GetResults");
		Print("GetResults execution finished (or at least the WS call)! Job done!");
		system.FreeArrays();
	}
	
	//EventSetTimer(4);
	return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
	GlobalContext.DatabaseLog.CallBulkWebServiceProcedure("BulkDebugLog", true);
	system.PrintDeInitReason(reason);
	system.CleanTranData();
	system.RemoveUnusedDecisionsTransactionsAndLots();
	
	if((_Symbol != CurrentSymbol) && (!StringIsNullOrEmpty(CurrentSymbol)))
		GlobalContext.Config.ChangeSymbol(CurrentSymbol, PERIOD_CURRENT);
}
