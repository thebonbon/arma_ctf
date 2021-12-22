/*
 * Author: TheBonBon
 * Spawn Capture Flag Mission
 *
 * Arguments:
 * 0: Defend Radius <NUM>
 * 1: Capture Speed <NUM> (Slow 100 | Normal 10 | Fast 1 )
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [50, 10] call BON_fnc_SpawnFlag
 *
 * 
 */

BON_fnc_SpawnFlag = {
	params["_defendRadius", "_captureSpeed"];

	CapturingSide = sideUnknown;

	_allLocationTypes = ["NameVillage","NameCity","NameCityCapital"];
	_allLocations = nearestLocations [[0,0,0], _allLocationTypes, 1000000];

	if (count _allLocations < 1) exitWith {systemChat "Failed to spawn Flag (no pos found)";};

	_defendLocation = selectRandom _allLocations;
	
	//Create Task
	[west, "dT1", ["Defend the target location at all cost! Make sure to bring building materials to fortify the area", "Defend location", ""], position _defendLocation, "AUTOASSIGNED", 1, true] call BIS_fnc_taskCreate;
	["dT1","defend"] call BIS_fnc_taskSetType;

	//Create Maker
	_defendMarker = createMarker ["DefendMarker", position _defendLocation];
	_defendMarker setMarkerShape "ELLIPSE"; 
	_defendMarker setMarkerSize [_defendRadius, _defendRadius];
	_defendMarker setMarkerColor "ColorRed";
	_defendMarker setMarkerAlpha 0.5;

	//Create Flagpole
	_defendFlag = "FlagPole_F" createVehicle position _defendLocation;
	_defendFlag setFlagTexture "\A3\Data_F\Flags\Flag_CSAT_CO.paa";
	_defendFlag setVariable ["BON_flagSide", east, true];
	[_defendFlag, 1, true] spawn BIS_fnc_animateFlag;
	[_defendFlag, _defendLocation, _defendRadius] spawn BON_fnc_CheckArea; // Start Loop
	[_defendFlag, _captureSpeed] spawn BON_fnc_CaptureFlag;

	//Spawn Enemys
	//...

};

BON_fnc_CheckArea = {
	params["_flag", "_defendLocation", "_defendRadius"];
	while {sleep 1; true} do {

		CapturingSide = sideUnknown;
		_allUnitsInArea = (position _defendLocation) nearEntities ["Man",  _defendRadius];
		_enemysInArea = ({side _x == east && alive _x} count _allUnitsInArea) > 0;
		_allyInArea = ({side _x == west && alive _x} count _allUnitsInArea) > 0;

		if (!_enemysInArea && _allyInArea) then { 	// Capture Ally
			CapturingSide = west; 
		}; 
		if (_enemysInArea && !_allyInArea) then { 	// Capture Enemy
			CapturingSide = east;
		};
		
	};
};

BON_fnc_CaptureFlag = {
	params["_flag", "_captureSpeed"];
	while {sleep 1; true} do {
		if (CapturingSide != sideUnknown) then {
			_nextUpFlagPhase = flagAnimationPhase _flag + (10 / _captureSpeed);
			_nextDownFlagPhase = flagAnimationPhase _flag - (10 / _captureSpeed);
			//Capture ALLY
			if (CapturingSide == west) then {
				if ((_flag getVariable "BON_flagSide") == east) then {
					[_flag, _nextDownFlagPhase, _captureSpeed] call BIS_fnc_animateFlag;
					if (flagAnimationPhase _flag == 0) then {
						_flag setVariable ["BON_flagSide", west, true];
						_flag setFlagTexture "\A3\Data_F\Flags\Flag_NATO_CO.paa";
					};
				} else {
					[_flag, _nextUpFlagPhase, _captureSpeed] call BIS_fnc_animateFlag;
					if (flagAnimationPhase _flag == 1) exitWith {	// WIN
						["dT1","SUCCEEDED"] call BIS_fnc_taskSetState;
						deleteMarker "DefendMarker";
					};
				};
				
			};	
			//Capture OPFOR
			if (CapturingSide == east) then {
				if ((_flag getVariable "BON_flagSide") == west) then {
					[_flag, _nextDownFlagPhase, _captureSpeed] call BIS_fnc_animateFlag;
					if (flagAnimationPhase _flag == 0) then {
						_flag setVariable ["BON_flagSide", east, true];
						_flag setFlagTexture "\A3\Data_F\Flags\Flag_CSAT_CO.paa";
					};
				} else {
					[_flag, _nextUpFlagPhase, _captureSpeed] call BIS_fnc_animateFlag;
				};
				
			};
		};
	}
};