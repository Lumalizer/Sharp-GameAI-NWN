#include "NW_I0_GENERIC"
#include "our_constants"

void ShoutClosestEnemyLocation(object oPC) {
	object oClosestEnemy = GetNearestObject(OBJECT_TYPE_CREATURE, oPC, 1);

	if (GetIsObjectValid(oClosestEnemy) && GetIsEnemy(oPC, oClosestEnemy)) {
		string sEnemyName = GetName(oClosestEnemy);
		string sMessage = "The closest enemy is: " + sEnemyName;
		SpeakString(sMessage, TALKVOLUME_SHOUT);
	} else {
		// SpeakString("No enemies nearby.", TALKVOLUME_SHOUT);
	}
}

string T2_GetRandomTarget(object self) {
	// The next line moves to the spawn location of the similar opponent
	// ActionMoveToLocation( GetLocation( GetObjectByTag( "WP_" + OpponentColor( OBJECT_SELF ) + "_"
	// + IntToString( GetLocalInt( OBJECT_SELF, "INDEX" ) ) ) ), TRUE );

	if (IsWizardLeft(self))
		return WpClosestAltarLeft();
	else if (IsWizardRight(self))
		return WpClosestAltarRight();

	int iTarget = 0;

	if (IsMaster(self))
		iTarget = Random(8);
	else
		iTarget = Random(10);

	if (iTarget < 4)
		return WpDoubler();
	else if (iTarget < 6)
		return WpFurthestAltarLeft();
	else if (iTarget < 8)
		return WpFurthestAltarRight();
	else {
		int iTarget = Random(2);
		if (iTarget == 0)
			return WpClosestAltarLeft();
		else
			return WpClosestAltarRight();
	}
	return "";
}

string T2_GetTargetAltar(string condition) {
	string c_AL = WpClosestAltarLeft();
	string c_AR = WpClosestAltarRight();
	string f_AL = WpFurthestAltarLeft();
	string f_AR = WpFurthestAltarRight();
	string doubler = WpDoubler();

	int emptyCount = 0;
	if (ClaimerOf(c_AL) == condition) emptyCount++;
	if (ClaimerOf(c_AR) == condition) emptyCount++;
	if (ClaimerOf(f_AL) == condition) emptyCount++;
	if (ClaimerOf(f_AR) == condition) emptyCount++;
	if (ClaimerOf(doubler) == condition) emptyCount++;

	if (emptyCount == 0) return "";

	int randomInt = Random(emptyCount) + 1;

	if (ClaimerOf(c_AL) == condition) {
		randomInt--;
		if (randomInt == 0) return c_AL;
	}
	if (ClaimerOf(c_AR) == condition) {
		randomInt--;
		if (randomInt == 0) return c_AR;
	}
	if (ClaimerOf(f_AL) == condition) {
		randomInt--;
		if (randomInt == 0) return f_AL;
	}
	if (ClaimerOf(f_AR) == condition) {
		randomInt--;
		if (randomInt == 0) return f_AR;
	}
	if (ClaimerOf(doubler) == condition) {
		randomInt--;
		if (randomInt == 0) return doubler;
	}

	return "";
}
string T2_GetNotSoRandomTarget(object self) {
	string sMyColor = MyColor(self);
	string sOpponentColor = OpponentColor(self);

	string emptyAltar = T2_GetTargetAltar("");
	if (emptyAltar != "") return emptyAltar;

	string defAltar = T2_GetTargetAltar(sMyColor);
	string attackAltar = T2_GetTargetAltar(sOpponentColor);
	string targetAltar = "";
	string mode = "";

	if (defAltar != "") {
		targetAltar = defAltar;
		mode = "defend";
	} else if (attackAltar != "") {
		targetAltar = attackAltar;
		mode = "attack";
	} else
		return GetRandomTarget();

	object oAltar = GetObjectByTag(targetAltar);
	object oEnemy = GetNearestCreature(1, 1, oAltar, 1, -1, 2, 1);

	if (mode == "defend") {
		// Assuming 5.0 is a reasonable distance to detect threats
		if (GetIsObjectValid(oEnemy) && GetDistanceBetween(oAltar, oEnemy) <= 5.0)
			return targetAltar;

	} else if (mode == "attack") {
		// Assuming 5.0 is a reasonable distance to detect defenders
		if (!GetIsObjectValid(oEnemy) || GetDistanceBetween(oAltar, oEnemy) > 5.0)
			return targetAltar;
	}

	return GetRandomTarget();
}

int T2_DetermineNeedNewTarget(object oTarget, string sTarget, object self) {
	// If there is a member of my own team close to the target and closer than me,
	// and no enemy is closer and this other member is not in combat and
	// has the same target, then choose a new target.
	float fToTarget = GetDistanceToObject(oTarget);
	int i = 1;
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	while (GetIsObjectValid(oCreature)) {
		if (GetLocation(oCreature) == GetLocation(self)) break;
		if (GetDistanceBetween(oCreature, oTarget) > fToTarget) break;
		if (GetDistanceBetween(oCreature, oTarget) > 5.0) break;
		if (!SameTeam(oCreature)) break;
		if (GetIsInCombat(oCreature)) break;
		if (GetLocalString(oCreature, "TARGET") == sTarget) {
			return TRUE;
			break;
		}
		++i;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	}
	return FALSE;
}

// sets a new target, if needed, and returns the distance to the target
float T2_SetNewTargetIfNeeded(object oTarget, string sTarget, object self) {
	// if the new target is not valid, then choose another new target
	int j = 0;
	while (T2_DetermineNeedNewTarget(oTarget, sTarget, self)) {
		++j;
		sTarget = T2_GetNotSoRandomTarget(self);
		SetLocalString(self, "TARGET", sTarget);
		oTarget = GetObjectByTag(sTarget);
		if (j > 5) break;
	}

	if (j > 0) {
		string sMessage = "Going to: " + sTarget;
		SpeakString(sMessage, TALKVOLUME_SHOUT);
	}

	if (!GetIsObjectValid(oTarget)) return 0.0;
	return GetDistanceToObject(oTarget);
}

void T2_DoHealing() {
	if (TalentHeal()) {
		SpeakString("I am healing.", TALKVOLUME_SHOUT);
		return;
	}
}
// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T2_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	T2_DoHealing();
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

// Called every heartbeat (i.e., every six seconds).
void T2_HeartBeat() {
	ShoutClosestEnemyLocation(OBJECT_SELF);

	if (GetIsInCombat()) return;

	T2_DoHealing();

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") return;

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) return;

	float fToTarget = T2_SetNewTargetIfNeeded(oTarget, sTarget, OBJECT_SELF);

	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

// Called when the NPC is spawned.
void T2_Spawn() {
	string sTarget = T2_GetNotSoRandomTarget(OBJECT_SELF);
	string sMessage = "Going to: " + sTarget;
	SpeakString(sMessage, TALKVOLUME_SHOUT);
	SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	ActionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

// This function is called when certain events take place, after the standard
// NWN handling of these events has been performed.
void T2_UserDefined(int Event) {
	switch (Event) {
		// The NPC has just been attacked.
		case EVENT_ATTACKED:
			break;

		// The NPC was damaged.
		case EVENT_DAMAGED:
			break;

		// At the end of one round of combat.
		case EVENT_END_COMBAT_ROUND:
			break;

		// Every heartbeat (i.e., every six seconds).
		case EVENT_HEARTBEAT:
			T2_HeartBeat();
			break;

		// Whenever the NPC perceives a new creature.
		case EVENT_PERCEIVE:
			break;

		// When a spell is cast at the NPC.
		case EVENT_SPELL_CAST_AT:
			break;

		// Whenever the NPC's inventory is disturbed.
		case EVENT_DISTURBED:
			break;

		// Whenever the NPC dies.
		case EVENT_DEATH:
			break;

		// When the NPC has just been spawned.
		case EVENT_SPAWN:
			T2_Spawn();
			break;
	}

	return;
}

// Called when the fight starts, just before the initial spawning.
void T2_Initialize(string sColor) { SetTeamName(sColor, "Team-" + GetStringLowerCase(sColor)); }
