#include "NW_I0_GENERIC"
#include "our_constants"

int T4_GetHealthTeam(int ourTeam, object oMe = OBJECT_SELF) {
	string color = MyColor(oMe);
	if (!ourTeam) {
		color = OpponentColor(oMe);
	}

	int total = 0;
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_1"));
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_2"));
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_3"));
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_4"));
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_5"));
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_6"));
	total = total + GetHealth(GetObjectByTag("NPC_" + color + "_7"));

	return total;
}

int T4_GetDifferenceTeamHealth() {
	int ourhealth = T4_GetHealthTeam(TRUE, OBJECT_SELF);
	int enemyhealth = T4_GetHealthTeam(FALSE, OBJECT_SELF);

	return ourhealth - enemyhealth;
}

int T4_PointsPerTurn(int ourTeam = TRUE, object oMe = OBJECT_SELF) {
	int PPT = 0;
	string sColor = MyColor(oMe);
	if (!ourTeam) sColor = OpponentColor(oMe);

	// for each altar owned by this team, add one to their score
	if (ClaimerOf(ALTAR_BLUE_1) == sColor) PPT = PPT + 1;
	if (ClaimerOf(ALTAR_BLUE_2) == sColor) PPT = PPT + 1;
	if (ClaimerOf(ALTAR_RED_1) == sColor) PPT = PPT + 1;
	if (ClaimerOf(ALTAR_RED_2) == sColor) PPT = PPT + 1;

	// if this team owns the doubler, double their points
	if (ClaimerOf(DOUBLER) == sColor) PPT = PPT * 2;

	return PPT;
}

int T4_GetPointAdvantage() {
	int ourPPT = T4_PointsPerTurn(TRUE, OBJECT_SELF);
	int enemyPPT = T4_PointsPerTurn(FALSE, OBJECT_SELF);

	return ourPPT - enemyPPT;
}

// check if we are currently employing a defensive strategy
int T4_IsDefensive(object oMe = OBJECT_SELF) {
	if (GetLocalString(MyPortal(GetObjectByTag(TagMaster(oMe))), "CURRENT_STRATEGY") == "DEFENSIVE")
		return TRUE;
	return FALSE;
}

// check if we are currently employing an offensive strategy
int T4_IsOffensive(object oMe = OBJECT_SELF) {
	if (GetLocalString(MyPortal(GetObjectByTag(TagMaster(oMe))), "CURRENT_STRATEGY") == "OFFENSIVE")
		return TRUE;
	return FALSE;
}

int T4_IsDoubler(object oMe = OBJECT_SELF) {
	if (GetLocalString(MyPortal(GetObjectByTag(TagMaster(oMe))), "CURRENT_STRATEGY") == "DOUBLER")
		return TRUE;
	return FALSE;
}

void T4_SetStrategy(string strat, object oMe = OBJECT_SELF) {
	SetLocalString(MyPortal(GetObjectByTag(TagMaster(oMe))), "CURRENT_STRATEGY", strat);
}

void T4_SetDefensive(object oMe = OBJECT_SELF) { T4_SetStrategy("DEFENSIVE", oMe); }

void T4_SetOffensive(object oMe = OBJECT_SELF) { T4_SetStrategy("OFFENSIVE", oMe); }

void T4_SetDoubler(object oMe = OBJECT_SELF) { T4_SetStrategy("DOUBLER", oMe); }

string T4_GetAttackPosition(object oMe = OBJECT_SELF) {
	string sTarget = "WP_ALTAR_" + OpponentColor(oMe) + "_";

	if (IsMaster(oMe))
		sTarget = "WP_CENTRE_" + MyColor(oMe) + "_2";
	else if (IsWizardRight(oMe))
		sTarget = sTarget + "1";
	else if (IsWizardLeft(oMe))
		sTarget = sTarget + "2";
	else if (IsClericRight(oMe))
		sTarget = sTarget + "1B";
	else if (IsClericLeft(oMe))
		sTarget = sTarget + "2B";
	else if (IsFighterRight(oMe))
		sTarget = sTarget + "1A";
	else if (IsFighterLeft(oMe))
		sTarget = sTarget + "2A";

	return sTarget;
}

string T4_GetDefensivePosition(object oCreature = OBJECT_SELF) {
	string c_AL = WpClosestAltarLeft();
	string c_AR = WpClosestAltarRight();
	string f_AL = WpFurthestAltarLeft();
	string f_AR = WpFurthestAltarRight();
	string d = WpDoubler();

	string sTarget = "WP_ALTAR_" + MyColor(oCreature) + "_";

	if (IsMaster(oCreature))
		sTarget = d;
	else if (IsWizardRight(oCreature))
		sTarget = sTarget + c_AL;
	else if (IsWizardLeft(oCreature))
		sTarget = sTarget + c_AL;
	else if (IsClericRight(oCreature))
		sTarget = sTarget + c_AL;
	else if (IsClericLeft(oCreature))
		sTarget = sTarget + c_AL;
	else if (IsFighterRight(oCreature))
		sTarget = sTarget + c_AL;
	else if (IsFighterLeft(oCreature))
		sTarget = sTarget + c_AL;

	return sTarget;
}

string T4_GetDoublerPosition() { return ""; }

string T4_GetBestStrategy() {
	if (GetScore(MyColor(OBJECT_SELF)) > 2 * GetScore(OpponentColor(OBJECT_SELF))) {
		return "DEFENSE";
	}

	if (T4_GetDifferenceTeamHealth() < -30) {
		return "DEFENSE";
	} else if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_7"),
								  GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_5")) > 20.0) {
		return "DEFENSE";
	} else if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_1"),
								  GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_3")) > 20.0) {
		return "DEFENSE";
	}

	if (T4_GetDifferenceTeamHealth() > 0) {
		if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_7"),
							   GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_5")) < 20.0) {
			return "OFFENSE";
		} else if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_1"),
									  GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_3")) <
				   20.0) {
			return "OFFENSE";
		}
	}

	return "DEFENSE";
}

// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T4_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

// Called every heartbeat (i.e., every six seconds).
void T4_HeartBeat() {
	// if in combat, let it do combat stuff automatically, anything we want to do differently, do so
	// before
	if (GetIsInCombat()) return;

	// on the turn of the first NPC (right wizard), check which strategy to employ
	if (IsWizardRight(OBJECT_SELF)) {
		string strat = T4_GetBestStrategy();
		T4_SetStrategy(strat, OBJECT_SELF);
	}

	// now, do the behavior as defined for offensive and defensive play
	if (T4_IsOffensive(OBJECT_SELF)) {
		// TODO: define offensive behavior here
	}
	if (T4_IsDefensive(OBJECT_SELF)) {
		// get the normal defensive position
		string sTarget = T4_GetDefensivePosition(OBJECT_SELF);
		SpeakString("My target is: " + sTarget, TALKVOLUME_SHOUT);
		// now set this as the current target
		SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	}

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") return;

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) return;

	float fToTarget = GetDistanceToObject(oTarget);
	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

void T4_Spawn() {
	if (GetLocalString(MyPortal(GetObjectByTag(TagMaster(OBJECT_SELF))), "CURRENT_STRATEGY") == "")
		SetLocalString(MyPortal(GetObjectByTag(TagMaster(OBJECT_SELF))), "CURRENT_STRATEGY",
					   "DEFENSIVE");

	string sTarget = "";

	if (T4_IsOffensive(OBJECT_SELF)) {
	}
	if (T4_IsDefensive(OBJECT_SELF)) {
		sTarget = T4_GetDefensivePosition(OBJECT_SELF);
		SpeakString("setting defensive target", TALKVOLUME_SHOUT);
	}

	SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	ActionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

void T4_UserDefined(int Event) {
	switch (Event) {
		case EVENT_ATTACKED:
			break;

		case EVENT_DAMAGED:
			break;

		case EVENT_END_COMBAT_ROUND:
			break;

		case EVENT_HEARTBEAT:
			T4_HeartBeat();
			break;

		case EVENT_PERCEIVE:
			break;

		case EVENT_SPELL_CAST_AT:
			break;

		case EVENT_DISTURBED:
			break;

		case EVENT_DEATH:
			break;

		case EVENT_SPAWN:
			T4_Spawn();
			break;
	}

	return;
}

void T4_Initialize(string sColor) {
	SetTeamName(sColor, "offense/defense-" + GetStringLowerCase(sColor));
}