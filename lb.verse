
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors/NamedColors }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /Fortnite.com/AI }
using { config.ui_config}

lb := class(creative_device):

    var PlayerPoints : [agent]player_score = map{}

    LeaderboardMsg<localizes>:message = "Leaderboard"
    AllPlayersMsg<localizes>:message = "All Players and scores"

    @editable
    PlayerSpawner : player_spawner_device = player_spawner_device{}

    @editable
    IncreasePointsBtn : button_device = button_device{}

    @editable
    ShowLBBtn : button_device = button_device{}

    @editable
    LbUIStyle : lb_ui_style = lb_ui_style{}

    var UIPerPlayer : [agent]?canvas = map{}

    OnBegin<override>()<suspends>:void=
        spawn{AddToMap()}
        spawn{IncreasePoints()}
        spawn{ShowLB()}
        
    IncreasePoints()<suspends>:void=
        loop:
            Agent := IncreasePointsBtn.InteractedWithEvent.Await()
            if(ScoreObj := PlayerPoints[Agent]):
                Print("{set ScoreObj.Points += 5}")

    ShowLB()<suspends>:void=
        loop:
            ShowLBBtn.InteractedWithEvent.Await()
            for(Player : GetPlayspace().GetPlayers(), PlayerUI := GetPlayerUI[Player]):
                PlayerUI.AddWidget(CreateLeaderboardCanvas(Player), player_ui_slot . InputMode := ui_input_mode.All)
            Sleep(5.0)
            for(Player : GetPlayspace().GetPlayers(), PlayerUI := GetPlayerUI[Player]):
                if(UIToRemove := UIPerPlayer[Player]?) then PlayerUI.RemoveWidget(UIToRemove)
            
    AddToMap()<suspends>:void= 
        loop:
            Agent := PlayerSpawner.SpawnedEvent.Await()
            if(not PlayerPoints[Agent], set PlayerPoints[Agent] = player_score{Agent := option{Agent}}){}


    (InArray : []player_score).SortObj():[]player_score=
        var SortedArray : []player_score = InArray
        for(I := 0..SortedArray.Length - 1):
            for(J := 0..SortedArray.Length - 1 ):
                if(SortedArray[J].Points < SortedArray[J + 1].Points):
                    if:
                        HigherVal := SortedArray[J]
                        LowerVal := SortedArray[J + 1]
                        set SortedArray[J] = LowerVal
                        set SortedArray[J + 1] = HigherVal
        return SortedArray



    CreateLeaderboardCanvas(Agent : agent):canvas=
        LeaderStatsStackBox := stack_box{Orientation := orientation.Vertical}
        var AllStats : []player_score = array:
            player_score{Agent := false, Points := 20000000000000}
            player_score{Agent := false, Points := 85}
            player_score{Agent := false, Points := 1}
        for(GivenAgent -> PlayerStat :PlayerPoints):
            set AllStats += array{PlayerStat}
        set AllStats = AllStats.SortObj()
        for(Index -> PlayerStat : AllStats):
            var Col : color = if(Mod[Index + 1, 2] = 0) then LbUIStyle.PrimaryPlayerBG else LbUIStyle.SecondaryPlayerBG
            BGPlayerOpacity : type{_X:float where 0.0 <= _X, _X <= 1.0} = if(Mod[Index, 2] = 0) then LbUIStyle.PrimaryPlayerBGOpacity else LbUIStyle.SecondaryPlayerBGOpacity
            TextColor : color = if(Index + 1 = 1):
                LbUIStyle.FirstPlaceTextColor 
            else if(Index + 1 = 2):
                LbUIStyle.SecondPlaceTextColor
            else if(Index + 1 = 3):
                LbUIStyle.ThirdPlaceTextColor
            else:
                LbUIStyle.DefaultPlaceTextColor
            StatObj := stat_ui{BGColor := Col, MaybeAgent := PlayerStat.Agent, PlayerPos := Index + 1, PlayerScore := PlayerStat.Points, PlayerBGOpacity := BGPlayerOpacity, TextColor := TextColor}
            LeaderStatsStackBox.AddWidget(
                stack_box_slot:
                    Widget := StatObj.MakeStatUI()
                    HorizontalAlignment := HorFill
            )
        LeaderboardOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block:
                        DefaultOpacity := 0.0
                        DefaultDesiredSize := vector2{X:= 897.263977, Y := 870.909424}
                overlay_slot:
                    Widget := text_block:
                        DefaultText := AllPlayersMsg
                        DefaultTextColor := White
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerTop
                    Padding := margin{Top := 15.0}
                overlay_slot:
                    Widget := LeaderStatsStackBox
                    HorizontalAlignment := HorFill
                    VerticalAlignment := VerTop
                    Padding := margin{Top := 75.0}
        LeaderboardWrapperOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block:
                        DefaultColor := LbUIStyle.LeaderboardBG
                        DefaultDesiredSize := vector2{X:= 1069.799561, Y := 1023.642273}
                        DefaultOpacity := LbUIStyle.LeaderboardBGOpacity
                overlay_slot:
                    Widget := text_block:
                        DefaultText := LeaderboardMsg
                        DefaultTextColor := White
                    Padding := margin{Top := 50.0}
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerTop
                overlay_slot:
                    Widget := LeaderboardOverlay
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerCen
                    Padding := margin{Top := 50.0}
        WrapperOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := LeaderboardWrapperOverlay
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerCen
        MainCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := WrapperOverlay
                    Anchors := anchors{Minimum := vector2{X:= 0.0, Y:= 0.0}, Maximum := vector2{X:= 1.0, Y:= 1.0}}
        if(set UIPerPlayer[Agent] = option{MainCanvas}){}
        return MainCanvas
player_score := class:

    Agent : ?agent

    var Points : int = 0

stat_ui := class:

    BGColor : color 

    MaybeAgent : ?agent

    PlayerPos : int 
    
    PlayerScore : int 

    ScoreMsg<localizes>:message = "Score:"

    PlayerBGOpacity : type{_X:float where 0.0 <= _X, _X <= 1.0}

    TextColor : color

    MakeStatUI():overlay=
        return overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block:
                        DefaultColor := BGColor
                        DefaultDesiredSize := vector2{Y := 63.796925}
                        DefaultOpacity := PlayerBGOpacity
                    HorizontalAlignment := HorFill
                overlay_slot:
                    Widget := text_block:
                        DefaultText := if(Agent := MaybeAgent?) then A2M(Agent) else S2M("John Doe") 
                        DefaultTextColor := TextColor
                    HorizontalAlignment := HorLeft
                    VerticalAlignment := VerCen
                    Padding := margin{Left := 75.0}
                overlay_slot:
                    Widget := text_block:
                        DefaultText := ConcatenateMessages(ScoreMsg, I2M(PlayerScore))
                        DefaultTextColor := TextColor
                    HorizontalAlignment := HorRight
                    VerticalAlignment := VerCen
                    Padding := margin{Right := 50.0}
                overlay_slot:
                    Widget := color_block:
                        DefaultColor := TextColor
                        DefaultDesiredSize := vector2{X := 80.682571, Y := 6.223558}
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerCen
                overlay_slot:
                    Widget := text_block:
                        DefaultText := S2M("#{PlayerPos}")
                        DefaultTextColor := TextColor
                    HorizontalAlignment := HorLeft
                    VerticalAlignment := VerCen
                    Padding := margin{Left := 15.0}


lb_ui_style := class<concrete>:

    @editable
    LeaderboardBG : color =MakeColorFromHex("229CFFFF")

    @editable
    PrimaryPlayerBG : color = MakeColorFromHex("10C4FFFF")

    @editable
    SecondaryPlayerBG : color = MakeColorFromHex("66CDFFFF")

    @editable
    LeaderboardBGOpacity : type{_X:float where 0.0 <= _X, _X <= 1.0} = 1.0

    @editable
    PrimaryPlayerBGOpacity : type{_X:float where 0.0 <= _X, _X <= 1.0} = 1.0

    @editable
    SecondaryPlayerBGOpacity : type{_X:float where 0.0 <= _X, _X <= 1.0} = 1.0

    @editable
    FirstPlaceTextColor : color = color{}
    
    @editable
    SecondPlaceTextColor : color = color{}

    @editable
    ThirdPlaceTextColor : color = color{}

    @editable
    DefaultPlaceTextColor : color = White
