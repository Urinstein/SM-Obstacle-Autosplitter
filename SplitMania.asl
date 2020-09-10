// Shootmania Obstacle Autosplitter
// v0.3 by Urinstein

/*	current issues:
	- only works in Single Map Local Play	<- appears to be ridiculously complicated to solve, not worth it
	- resetting on last CP causes a "goal" split	<- no idea how to solve thios, but would be really good to do
	- going on the wrong map in a multi map run might ruin splits	<- no intention of fixing this
*/

state("ManiaPlanet") {
	int cpLocalMap :	"ManiaPlanet.exe", 0x01C8BE20, 0x138, 0x58, 0x38, 0x10, 0x258;					// current CP in Single Map local games
	//int cpLocalNet :	"ManiaPlanet.exe", 0x01CD3938, 0x930, 0x38, 0x0, 0x770, 0x20, 0x10, 0x6B0;		// current CP in local networks
	int maxCP :			"ManiaPlanet.exe", 0x01C8BE20, 0x138, 0x58, 0x18, 0x10, 0xDF8;					// No. of Cps on current map
	//int serverTime :	"ManiaPlanet.exe", 0x01CA08A8, 0x8C;											// this one comes with ms but they seem to be inaccurate
	int serverTime :	"ManiaPlanet.exe", 0x1D04724;
	bool onMap :		"ManiaPlanet.exe", 0x1BDDEAB;													// whether or not a map is currently loaded (detects menus and loading screens, so to say)
	bool running :		"ManiaPlanet.exe", 0x1C7179B;													// whether the player is currently running (as opposed to waiting to be spawned for a run)
}

state("ManiaPlanet32") {
	// no workerino
}

startup {
	refreshRate = 100;
	
	settings.Add("everyCP", true, "Split on every CP");
	settings.Add("CPgoal", true, "Split on Goal");
	
		// Specific CP settings	//
	for (int j = 1; j < 10; j++)
	{
			//	CP setting groups	//
		string groupCode = "Map" + j.ToString(); 
		string groupName = "Map "  + j.ToString();
		string groupDescription = "Split on specific CPs on Map " + j.ToString();
		settings.Add(groupCode, false, groupName);
		settings.SetToolTip(groupCode, groupDescription);
		
		for (int i = 1; i < 100; i++)
		{
				//	CP settings	//
			string code = "CP" + j.ToString() + "." + i.ToString();
			string name = "CP"  + i.ToString() + " on Map " + j.ToString();
			settings.Add(code, false, name, groupCode);
		}
	}
}

init {
	vars.startTime = 0;
	vars.runTime = 0;
	vars.mapCtr = 1;
	vars.finishedMap = false;
	vars.startedNewMap = true;
}

update {
		//	new map loaded	//
	if (current.onMap && !old.onMap) {
		vars.finishedMap = false;
	}
	
		//	run on new map started	//
	if (!vars.finishedMap && current.running && !old.running) {
		vars.startedNewMap = true;
		vars.startTime = current.serverTime + 503 - vars.runTime;
		//print("update2");
	}
	
	
	//print(current.cpLocalNet.ToString());
}

start {
	if (current.running && !old.running) {
		vars.startTime = current.serverTime + 503;
		vars.runTime = 0;
		vars.mapCtr = 1;
		vars.finishedMap = false;
		vars.startedNewMap = true;
		return(true);
	}
}

split{
	if (vars.startedNewMap){
			//	Split on Goal	//
		if(settings["CPgoal"] && old.running && !current.running && old.cpLocalMap == current.maxCP) {
			vars.finishedMap = true;
			vars.startedNewMap = false;
			vars.mapCtr++;
			//print("split goal");
			return true;
		}
			//	Split every CP	//
		if (settings["everyCP"] && current.cpLocalMap - old.cpLocalMap == 1) {
			//print("split every CP");
			return true;
		}
			// Split specific CPs	//
		string specificSetting = "CP" + vars.mapCtr + "." + current.cpLocalMap;
		if (current.running == true && current.cpLocalMap != 0 && settings[specificSetting] && current.cpLocalMap - old.cpLocalMap == 1) {
			return true;
		}
	}
}

reset {
	if (vars.startedNewMap && !current.running && old.running && old.cpLocalMap != old.maxCP) {return true;}
}

isLoading
{
	return true;
}

gameTime
{
	if (vars.startedNewMap)	{vars.runTime = current.serverTime - vars.startTime;}
	return TimeSpan.FromMilliseconds(vars.runTime);
}