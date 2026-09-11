#if defined _pp_included
#endinput
#endif
#define _pp_included

// Different ways teams can be selected.
enum TeamType {
  TeamType_Manual,
  TeamType_Random,
  TeamType_Captains,
};

// Different ways the map can be selected.
enum MapType {
  MapType_Current,
  MapType_Vote,
  MapType_Veto,
};

// Permission checking values.
enum Permission {
  Permission_All,       // anyone can use the command
  Permission_Captains,  // only captains (and higher) can use the command (note: reverts to
                        // Permission_All when not using captains)
  Permission_Leader,    // only the pug leader (and higher) can use the command
  Permission_Admin,     // only pug admins can use the command
  Permission_None,      // this command is disabled
};

// Pug game state
enum GameState {
  GameState_None,                          // no setup has taken place
  GameState_Warmup,                        // setup done, waiting for players to ready up
  GameState_PickingPlayers,                // only used if TeamType_Captains is the teamtype
  GameState_WaitingForStart,               // waiting for a .start if autolive is disabled
  GameState_Countdown,                     // doing the countdown timer
  GameState_KnifeRound,                    // in the knife round
  GameState_WaitingForKnifeRoundDecision,  // waiting for a .stay/.swap command after the knife
                                           // round
  GameState_GoingLive,                     // in the lo3 process
  GameState_Live,                          // the match is live
};

enum ChatAliasMode {
  ChatAlias_Always,     // Alias is always enabled
  ChatAlias_WhenSetup,  // Alias is only available when game state is not GameState_None
};

/**
 * Called when a setup menu is opened.
 *
 * @param client Client that did the setup menu (e.g. the leader).
 * @param menu The menu being given to the client.
 * @return Whether to display the menu to the client or not.
 */
forward Action PugPlugin_OnSetupMenuOpen(int client, Menu menu, bool displayOnly);

/**
 * Called when a setup menu option is selected.
 * You should call PugPlugin_GiveSetupMenu to the calling client at the end of this function.
 */
forward void PugPlugin_OnSetupMenuSelect(Menu menu, int client, const char[] selected_info,
                                        int selected_position);

/**
 * Called when a setup is completed.
 */
forward void PugPlugin_OnSetup();

/**
 * Called when a client force-ends the match.
 *
 * @param client Client that force-ended the match.
 */
forward void PugPlugin_OnForceEnd(int client);

/**
 * Called when a player marks themselves as ready.
 */
forward void PugPlugin_OnReady(int client);

/**
 * Called when a player marks themselves as not ready.
 */
forward void PugPlugin_OnUnready(int client);

/**
 * Called when the match is ready to begin, for example
 * when all players are ready and the captains are now picking players.
 */
forward void PugPlugin_OnReadyToStart();

/**
 * Called when a team won the knife round and made their decision.
 */
forward void PugPlugin_OnKnifeRoundDecision(bool swapping);

/**
 * Called when the going-live process begins, before the lo3.
 */
forward void PugPlugin_OnGoingLive();

/**
 * Called after the last restart when the game is completely live.
 */
forward void PugPlugin_OnLive();

/**
 * Called after the warmup config is executed.
 */
forward void PugPlugin_OnWarmupCfgExecuted();

/**
 * Called after the live config is executed.
 */
forward void PugPlugin_OnLiveCfgExecuted();

/**
 * Called after the postgame config is executed.
 */
forward void PugPlugin_OnPostGameCfgExecuted();

/**
 * Called when the match is over.
 * If you plan on using the result of the demo file,
 * I'd suggest adding a slight delay from when this is called
 * to accomodate the time spent flushing the demo to disk.
 *
 * @param hasDemo whether a demo was being recorded
 * @param demoFileName the filename of the demo (including the .dem extension)
 */
forward void PugPlugin_OnMatchOver(bool hasDemo, const char[] demoFileName);

/**
 * Called when a client is not picked in a captain-selection game.
 */
forward void PugPlugin_OnNotPicked(int client);

/**
 * Called every timer-check for whether the pug is ready to start or not.
 */
forward void PugPlugin_OnReadyToStartCheck(int readyPlayers);

/**
 * Called when user permissions are being checked. You can change
 * the value of "allow" to change the result of the check and allow
 * or disallow an action.
 *
 * @param client Client that initiated the command
 * @param command The command that was issued
 * @param p Default permissions the plugin checked against
 * @param allow Result of the check
 * @note permissions-checking is only relevent for pug-plugin commands.
 */
forward void PugPlugin_OnPermissionCheck(int client, const char[] command, Permission p,
                                        bool& allow);

/**
 * Called when a tv_record command is about to be sent.
 *
 * @param demoName The name given when the tv_record command was used (no .dem file extension)
 */
forward void PugPlugin_OnStartRecording(char[] demoName);

/**
 * Called before a player gets added to a captain selection menu.
 *
 * @param menu The Menu players are being added to
 * @param client The client being added to the menu
 * @param menuString The menu display string being added for the client
 * @param length Length of the menuString
 */
forward void PugPlugin_OnPlayerAddedToCaptainMenu(Menu menu, int client, char[] menuString,
                                                 int length);

/**
 * Called when a client issues a .help command in chat.
 *
 * @param client The client issuing the command
 * @param replyMessages An ArrayList of Strings to reply with (in chat)
 * @param maxMessageSize The max length of a string in the replyMessages list
 * @param block Whether to block the reply message (set to true to have no reply)
 */
forward void PugPlugin_OnHelpCommand(int client, ArrayList replyMessages, int maxMessageSize,
                                    bool& block);

/**
 * Called during any game state change.
 */
forward void PugPlugin_OnGameStateChanged(GameState before, GameState after);

// Sets a game up with the given settings.
native void PugPlugin_SetupGame(TeamType teamType, MapType mapType = MapType_Vote,
                               int playersPerTeam = 5, bool recordDemo = false,
                               bool knifeRound = false, bool autoLive = true);

// Sets the current game options. These can still be overwritten by a user with access to the .setup
// menu.
native void PugPlugin_SetSetupOptions(TeamType teamType, MapType mapType, int playersPerTeam = 5,
                                     bool recordDemo = false, bool knifeRound = false,
                                     bool autoLive = true);

// Fetches the current game options.
// @error If there is no game setup yet.
native void PugPlugin_GetSetupOptions(TeamType& teamType, MapType& mapType, int& playersPerTeam,
                                     bool& recordDemo, bool& knifeRound, bool& autoLive);

// Readies up a player, optionally printing chat messages
// to the client about readying up.
// Returns if they were successfully readied.
native bool PugPlugin_ReadyPlayer(int client, bool chatReply = true);

// Unreadies a player.
// Returns if they were successfully unreadied. (returns false if the client was already not-ready)
native bool PugPlugin_UnreadyPlayer(int client);

// Returns whether a client is ready.
// This is only valid when the game is setup AND not live.
native bool PugPlugin_IsReady(int client);

// Returns if the game settings have been setup.
native bool PugPlugin_IsSetup();

// Returns the team type being used.
// Only valid if PugPlugin_IsSetup is true.
native TeamType PugPlugin_GetTeamType();

// Returns the map type being used.
// Only valid if PugPlugin_IsSetup is true.
native MapType PugPlugin_GetMapType();

// Returns the current pug gamestate.
native GameState PugPlugin_GetGameState();

// Returns if there is currently a match setup.
native bool PugPlugin_IsMatchLive();

// Returns if the match is pending start. (e.g. during the lo3)
native bool PugPlugin_IsPendingStart();

// Sets the pug leader.
native void PugPlugin_SetLeader(int client);

// Returns the pug leader, or -1 if not set.
native int PugPlugin_GetLeader(bool allowLeaderReassignment = true);

// Sets who is a captain.
// A captain number is either 1 or 2.
native void PugPlugin_SetCaptain(int captainNumber, int client, bool printIfSame = false);

// Returns captain 1, or -1 if not set.
// A captain number is either 1 or 2.
native int PugPlugin_GetCaptain(int captainNumber);

// Prints a plugin-formatted message to a client.
native void PugPlugin_Message(int client, const char[] format, any:...);

// Prints a plugin-formatted message to all clients.
native void PugPlugin_MessageToAll(const char[] format, any:...);

// Returns the maximum number of players in the pug.
// Only valid if the game has already been setup.
native int PugPlugin_GetPugMaxPlayers();

// Returns the number of ready players required to start the pug.
native int PugPlugin_GetReadyToStart();

// Returns if a client was present when the game started.
// This doesn't include if the player disconnected and reconnected.
native bool PugPlugin_PlayerAtStart(int client);

// Returns if the plugin has identified a player as having elevated permissions.
native bool PugPlugin_IsPugAdmin(int client);

// Returns if a client satisfies a permission check.
native bool PugPlugin_HasPermissions(int client, Permission p, bool allowLeaderReassignment = true);

// Sets random captains.
native void PugPlugin_SetRandomCaptains();

// Adds a chat alias for a command. For example: .setup as a chat trigger for sm_setup
native void PugPlugin_AddChatAlias(const char[] alias, const char[] command,
                                  ChatAliasMode mode = ChatAlias_Always);

// Give a client the root setup menu again.
// This is intended to be called in the PugPlugin_OnSetupMenuSelect forward.
native void PugPlugin_GiveSetupMenu(int client, bool displayOnly = false, int menuPosition = -1);

// Displays the map change menu to a client (bypasses access checks).
native void PugPlugin_GiveMapChangeMenu(int client);

// Returns if a console command is a valid pug-plugin command.
native bool PugPlugin_IsValidCommand(const char[] command);

// Gets the permissions for a command, or throws an error on invalid command.
// Note: permissions-checking is only relevent for pug-plugin commands.
native Permission PugPlugin_GetPermissions(const char[] command);

// Sets the permissions for a command, returning whether the command already had permissions set.
// Note: permissions-checking is only relevent for pug-plugin commands.
native bool PugPlugin_SetPermissions(const char[] command, Permission p);

public SharedPlugin __pl_pp = {
    name = "pug-plugin",
    file = "pug-plugin.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_pp_SetNTVOptional() {
  MarkNativeAsOptional("PugPlugin_SetupGame");
  MarkNativeAsOptional("PugPlugin_GetSetupOptions");
  MarkNativeAsOptional("PugPlugin_SetSetupOptions");
  MarkNativeAsOptional("PugPlugin_ReadyPlayer");
  MarkNativeAsOptional("PugPlugin_UnreadyPlayer");
  MarkNativeAsOptional("PugPlugin_IsReady");
  MarkNativeAsOptional("PugPlugin_IsSetup");
  MarkNativeAsOptional("PugPlugin_GetTeamType");
  MarkNativeAsOptional("PugPlugin_GetMapType");
  MarkNativeAsOptional("PugPlugin_GetGameState");
  MarkNativeAsOptional("PugPlugin_IsMatchLive");
  MarkNativeAsOptional("PugPlugin_IsPendingStart");
  MarkNativeAsOptional("PugPlugin_SetLeader");
  MarkNativeAsOptional("PugPlugin_GetLeader");
  MarkNativeAsOptional("PugPlugin_SetCaptain");
  MarkNativeAsOptional("PugPlugin_GetCaptain");
  MarkNativeAsOptional("PugPlugin_Message");
  MarkNativeAsOptional("PugPlugin_MessageToAll");
  MarkNativeAsOptional("PugPlugin_GetPugMaxPlayers");
  MarkNativeAsOptional("PugPlugin_GetReadyToStart");
  MarkNativeAsOptional("PugPlugin_PlayerAtStart");
  MarkNativeAsOptional("PugPlugin_IsPugAdmin");
  MarkNativeAsOptional("PugPlugin_HasPermissions");
  MarkNativeAsOptional("PugPlugin_SetRandomCaptains");
  MarkNativeAsOptional("PugPlugin_AddChatAlias");
  MarkNativeAsOptional("PugPlugin_GiveSetupMenu");
  MarkNativeAsOptional("PugPlugin_GiveMapChangeMenu");
  MarkNativeAsOptional("PugPlugin_IsValidCommand");
  MarkNativeAsOptional("PugPlugin_GetPermissions");
  MarkNativeAsOptional("PugPlugin_SetPermissions");
}
#endif
