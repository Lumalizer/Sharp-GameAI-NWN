#include "NW_I0_GENERIC"
#include "our_constants"

void T4_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	DoHealing();
	DetermineCombatRound(oIntruder, nAI_Difficulty);
}

void T4_HeartBeat() {
	ShoutClosestEnemyLocation(OBJECT_SELF);

	if (GetIsInCombat()) return;

	DoHealing();

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") return;

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) return;

	float fToTarget = SetNewTargetIfNeeded(oTarget, sTarget, OBJECT_SELF);

	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

// return the health for one of the teams
int T4_GetHealthTeam(int ourTeam, object oMe = OBJECT_SELF) {
	// check for which color dependent on the team
	string color = MyColor(oMe);
	if (!ourTeam) {
		color = OpponentColor(oMe);
	}

	// now compute the total health for the entire team
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

// get the points earned per turn for the team
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

// return how much points we are earning each turn in comparison to the other team
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

// check if we are currently employing a doubler strategy
int T4_IsDoubler(object oMe = OBJECT_SELF) {
	if (GetLocalString(MyPortal(GetObjectByTag(TagMaster(oMe))), "CURRENT_STRATEGY") == "DOUBLER")
		return TRUE;
	return FALSE;
}

void T4_SetStrategy(string strat, object oMe = OBJECT_SELF) {
	SetLocalString(MyPortal(GetObjectByTag(TagMaster(oMe))), "CURRENT_STRATEGY", strat);
}

// set our current strategy to defensive
void T4_SetDefensive(object oMe = OBJECT_SELF) { T4_SetStrategy("DEFENSIVE", oMe); }

// set our current strategy to offensive
void T4_SetOffensive(object oMe = OBJECT_SELF) { T4_SetStrategy("OFFENSIVE", oMe); }

// set our current strategy to doubler
void T4_SetDoubler(object oMe = OBJECT_SELF) { T4_SetStrategy("DOUBLER", oMe); }

string T4_GetAttackPosition(object oMe = OBJECT_SELF) {
	// set the target based on what NPC
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
		sTarget = sTarget + "2B";  // B instead of E
	else if (IsFighterRight(oMe))
		sTarget = sTarget + "1A";
	else if (IsFighterLeft(oMe))
		sTarget = sTarget + "2A";  // A instead of C

	return sTarget;
}

string T4_GetDefensivePosition(object oMe = OBJECT_SELF) {
	// set the target based on what NPC
	string sTarget = "WP_ALTAR_" + MyColor(oMe) + "_";

	if (IsMaster(oMe))
		sTarget = "WP_CENTRE_" + MyColor(oMe) + "_2";
	else if (IsWizardRight(oMe))
		sTarget = sTarget + "1";
	else if (IsWizardLeft(oMe))
		sTarget = sTarget + "2";
	else if (IsClericRight(oMe))
		sTarget = sTarget + "1E";
	else if (IsClericLeft(oMe))
		sTarget = sTarget + "2E";
	else if (IsFighterRight(oMe))
		sTarget = sTarget + "1C";
	else if (IsFighterLeft(oMe))
		sTarget = sTarget + "2C";

	return sTarget;
}

string T4_GetDoublerPosition() {
	// TODO: implement this method
	return "";
}

string T4_GetBestStrategy() {
	// first check whether to use an interesting strategy here
	// if we are ahead by a lot, keep defending
	if (GetScore(MyColor(OBJECT_SELF)) > 2 * GetScore(OpponentColor(OBJECT_SELF))) {
		return "DEFENSE";
	}

	if (T4_GetDifferenceTeamHealth() < -30) {
		return "DEFENSE";
	} else if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_7"),
								  GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_5")) > 20.0) {
		// if distance between left wizard and left fighter is large (left fighter died), then
		// defend if health of team is low
		return "DEFENSE";
	} else if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_1"),
								  GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_3")) > 20.0) {
		// if distance between right wizard and right fighter is large (right fighter died), then
		// defend if health of team is low
		return "DEFENSE";
	}

	// check for other strategies, such as offense, doubler, etc.
	if (T4_GetDifferenceTeamHealth() > 0) {
		if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_7"),
							   GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_5")) < 20.0) {
			// if left wizard and left fighter are close to each other, and enough health, then
			// attack
			return "OFFENSE";
		} else if (GetDistanceBetween(GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_1"),
									  GetObjectByTag("NPC_" + MyColor(OBJECT_SELF) + "_3")) <
				   20.0) {
			// if right wizard and right fighter are close to each other, and enough health, then
			// attack
			return "OFFENSE";
		}
	}

	// otherwise return defense
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
		// SpeakString("My target is: " + sTarget, TALKVOLUME_SHOUT);
		// now set this as the current target
		SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	}

	// just some checks on whether the target is valid
	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") return;

	object oTarget = GetObjectByTag(sTarget);
	if (!GetIsObjectValid(oTarget)) return;

	float fToTarget = GetDistanceToObject(oTarget);
	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);

	return;
}

// Called when the NPC is spawned.
void T4_Spawn() {
	// on the first spawn
	if (GetLocalString(MyPortal(GetObjectByTag(TagMaster(OBJECT_SELF))), "CURRENT_STRATEGY") == "")
		// set our strategy to defensive
		SetLocalString(MyPortal(GetObjectByTag(TagMaster(OBJECT_SELF))), "CURRENT_STRATEGY",
					   "DEFENSIVE");

	// TODO: if melee character, drop ranged weapon

	// set target depending on current strategy and move there
	string sTarget = "";

	if (T4_IsOffensive(OBJECT_SELF)) {
		// define offensive behavior here
	}
	if (T4_IsDefensive(OBJECT_SELF)) {
		// define defensive behavior here
		sTarget = T4_GetDefensivePosition(OBJECT_SELF);
		SpeakString("setting defensive target", TALKVOLUME_SHOUT);
	}

	// now move to the location given by the strategy
	SetLocalString(OBJECT_SELF, "TARGET", sTarget);
	ActionMoveToLocation(GetLocation(GetObjectByTag(sTarget)), TRUE);
}

// This function is called when certain events take place, after the standard
// NWN handling of these events has been performed.
void T4_UserDefined(int Event) {
	switch (Event) {
		// The NPC has just been attacked.
		case EVENT_ATTACKED:
			// TODO: perhaps call for nearby units to assist in combat?
			break;

		// The NPC was damaged.
		case EVENT_DAMAGED:
			break;

		// At the end of one round of combat.
		case EVENT_END_COMBAT_ROUND:
			break;

		// Every heartbeat (i.e., every six seconds).
		case EVENT_HEARTBEAT:
			T4_HeartBeat();
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
			T4_Spawn();
			break;
	}

	return;
}

// Called when the fight starts, just before the initial spawning.
void T4_Initialize(string sColor) {
	SetTeamName(sColor, "offense/defense-" + GetStringLowerCase(sColor));
}