#-----------------------------------------------------------------------------#
#                   ► ABS Prexus 1.2 - New Edition◄                              
#
# Criado por Prexus
# Traduzido por Ogrim_Dooh
# New Edition(DEMO) por LegendsX
#
#-----------------------------------------------------------------------------#
# Dependências:                                                               #
#   RMXP Standard Development Kit (SDK)                                       #
#-----------------------------------------------------------------------------#
#--------------------------------------------------------------------------
# * SDK Log Script
#--------------------------------------------------------------------------

SDK.log('Prexus ABS', 'Prexus', 1, '18.12.05')
#--------------------------------------------------------------------------
# * Begin SDK Enable Test
#--------------------------------------------------------------------------

if SDK.state('Prexus ABS') == true
  
  #------------------------------------------------------------------------
  # * Action Battle System (ABS) Class
  #------------------------------------------------------------------------
  # The core class and functional epicenter of the Action Battle System
  #------------------------------------------------------------------------
  class ABS
    attr_accessor :p_animations
    attr_accessor :e_animations
    attr_accessor :player
    attr_accessor :enemies
    attr_accessor :events
    attr_accessor :event_triggers
    attr_reader   :enabled
    #----------------------------------------------------------------------
    # * Initialization Handlers
    #----------------------------------------------------------------------
    # Makes sure that everything is set up to start the ABS
    #----------------------------------------------------------------------
    def initialize
      @enabled = false
      @player = $game_party.actors[0] # Sets to leader player
      @enemies = {} # Enemy Hash
      @events = {} # Hash of Dead Events
      @event_triggers = {} # Hash of the Triggers of Dead Events
    end
    #----------------------------------------------------------------------
    def setup_enemies(events)
      @enemies = {} # Reset Enemy Hash
      for event in events.values
        parameters = SDK.event_comment_input(event, 3, 'ABS Setup')
        next if !parameters
        name = parameters[0].split
        troop = parameters[1].split
        trigger = parameters[2].split
        for monster in $data_enemies
          next if !monster
          if name[1].upcase == monster.name.upcase
            @enemies[event.id] = ABS::Enemy.new(monster.id)
            @enemies[event.id].event_id = event.id
            @enemies[event.id].troop = "ABS #{event.id}"
            @enemies[event.id].troop = troop[1].upcase unless troop[1] == nil
            @enemies[event.id].trigger_type = trigger[1].upcase
            @enemies[event.id].trigger = trigger[2]
          end
          break if @enemies[event.id] != nil
        end
      end
    end
    #----------------------------------------------------------------------
    def enable
      @enabled = true
      setup_enemies($game_map.events)
      $scene.hud_window.visible = true if $scene.is_a?(Scene_Map)
      update
    end
    #----------------------------------------------------------------------
    def disable
      @enabled = false
      for enemy in @enemies.values
        enemy.disengage
      end
      @enemies = {}
    end
    #----------------------------------------------------------------------
    # * Update Handlers
    #----------------------------------------------------------------------
    # Updates and refreshes any information regarding characters, enemies,
    # the ABS itself, or the graphic displays.
    #----------------------------------------------------------------------
    def update
      update_player # Checks and updates player related stuff
      for enemy in @enemies.values
        update_enemy(enemy) # Checks and updates enemy related stuff
      end
      update_status # Checks and updates engine related stuff
      update_hud # Checks and updates display related stuff
    end
    #----------------------------------------------------------------------
    def update_player
      @player = $game_party.actors[0] # Makes sure player is correct
      # Decrease cooldown
      @player.abs.chill if @player.abs.acted and @player.abs.cooldown != 0
      # Reset acted if cooldown is over
      @player.abs.acted = false if @player.abs.cooldown == 0
      # Reset variables if player's cooldown has been reset
      @player.abs.reset unless @player.abs.acted
    end
    #----------------------------------------------------------------------
    def update_enemy(enemy)
      enemy.find_player # Checks if player is close
      if enemy.engaged
        enemy.guarding = false # Resets guarding
        enemy.chill if enemy.cooldown != 0 # Decrease cooldown
        if enemy.cooldown == 0
          enemy.reset if enemy.check_ai # Reset timers
          enemy.cooldown /= 2 if enemy.guarding
        end
        enemy.path_find # Pathfind to the player
      end
      if enemy.dead?
        collect_spoils(enemy) # Collect items and exp
        remove(enemy) # Remove enemy based on its triggers
      end
    end
    #----------------------------------------------------------------------
    def update_status
      $game_temp.gameover = true if $game_party.all_dead? # End game if dead.
    end
    #----------------------------------------------------------------------
    def update_hud
      #hud shit goes here
    end
    #----------------------------------------------------------------------
    # * ABS Functions
    #----------------------------------------------------------------------
    # Handles anything regarding the ABS best done outside of other classes
    #----------------------------------------------------------------------
    def collect_spoils(enemy)
      exp = enemy.exp # Set to the enemy's EXP amount
      gold = enemy.gold # Set to the enemy's GOLD amount
      if rand(100) < enemy.treasure_prob # Random Probability of SPOIL
        if enemy.item_id > 0 # If its an ITEM
          treasure = $data_items[enemy.item_id]
        end
        if enemy.weapon_id > 0 # If its a WEAPON
          treasure = $data_weapons[enemy.weapon_id]
        end
        if enemy.armor_id > 0 # If its an ARMOR
          treasure = $data_armors[enemy.armor_id]
        end
      end
      @player.exp += exp unless @player.cant_get_exp? # Add Appropriate EXP
      $game_party.gain_gold(gold) # Add Appropriate GOLD
      case treasure
      when RPG::Item
        $game_party.gain_item(item.id, 1) # Add ITEM
      when RPG::Weapon
        $game_party.gain_weapon(item.id, 1) # Add WEAPON
      when RPG::Armor
        $game_party.gain_armor(item.id, 1) # Add ARMOR
      end
    end
    #----------------------------------------------------------------------
    def remove(enemy)
      @enemies.delete(enemy.event_id) # Remove dead enemy from hash
      case enemy.trigger_type
      when 'LOCAL' # If trigger is a local switch
        case enemy.trigger.upcase
        when 'A','B','C','D' # If the trigger is a valid trigger
          event = $game_map.events[enemy.event_id]
          key = [event.map_id, event.id, enemy.trigger.upcase]
          $game_self_switches[key] = true
          @events[event.id] = event
          @event_triggers[event.id] = enemy.trigger.upcase
          return
        end
      when 'SWITCH' # If the trigger is a switch
        if enemy.trigger.to_i > 0 # If the trigger is a valid switch
          $game_switches[enemy.trigger.to_i] = true
          return
        end
      when 'CHEST'
        event = $game_map.events[enemy.event_id]
        key = [event.map_id, event.id, 'A']
        $game_self_switches[key] = true
        @events[event.id] = event
        @event_triggers[event.id] = enemy.trigger_type.upcase
        return
      end
      # Else just remove the event lickity split.
      $game_map.events[enemy.event_id].character_name = ''
      $game_map.events[enemy.event_id].erase
    end
    #----------------------------------------------------------------------
    # * Calculation Functions
    #----------------------------------------------------------------------
    # Handles range and direction checks
    #----------------------------------------------------------------------
    def check_range(element, object, range = 0)
      element = $game_map.events[element.event_id] if element.is_a?(ABS::Enemy)
      object = $game_map.events[object.event_id] if object.is_a?(ABS::Enemy)
      x = (object.x - element.x) * (object.x - element.x)
      y = (object.y - element.y) * (object.y - element.y)
      r = x + y
      if r <= (range * range)
        return true
      end
      return false
    end
    #----------------------------------------------------------------------
    def find_range(element, object)
      element = $game_map.events[element.event_id] if element.is_a?(ABS::Enemy)
      object = $game_map.events[object.event_id] if object.is_a?(ABS::Enemy)
      x = (object.x - element.x) * (object.x - element.x)
      y = (object.y - element.y) * (object.y - element.y)
      return (x + y)
    end
    #----------------------------------------------------------------------
    def check_facing(element, object)
      element = $game_map.events[element.event_id] if element.is_a?(ABS::Enemy)
      object = $game_map.events[object.event_id] if object.is_a?(ABS::Enemy)
      if element.direction == 2
        return true if object.y >= element.y
      end
      if element.direction == 4
        return true if object.x <= element.x
      end
      if element.direction == 6
        return true if object.x >= element.x
      end
      if element.direction == 8
        return true if object.y <= element.y
      end
      return false
    end
    #----------------------------------------------------------------------
    # * ABS Animation Engine Functions
    #----------------------------------------------------------------------
    # Handles animating map sprites for a wide variety of uses
    #----------------------------------------------------------------------
    def animate(object, animation_name, position, wait = 8, frames = 0, repeat = 0)
      if object != nil
        object.animate(animation_name, position, frames, wait, repeat)
      end
    end
    #----------------------------------------------------------------------
    # * ABS Enemy Object
    #----------------------------------------------------------------------
    # This object handles interaction between the event and the enemy and
    # deals with all the attacks and such.
    #----------------------------------------------------------------------
    class Enemy < Game_Battler
      attr_accessor :event_id
      attr_accessor :engaged
      attr_accessor :trigger_type
      attr_accessor :trigger
      attr_accessor :cooldown
      attr_accessor :dis_cooldown
      attr_accessor :guarding
      attr_accessor :troop
      #--------------------------------------------------------------------
      # * Initialize Handlers
      #--------------------------------------------------------------------
      # Handles setting up all the stats and information needed by the ABS
      #--------------------------------------------------------------------
      def initialize(monster_id)
        super()
        @event_id = 0
        @enemy_id = monster_id
        @trigger_type = nil
        @trigger = nil
        @engaged = false
        @guarding = false
        @cooldown = 0
        @dis_cooldown = 0
        @move_type = 0
        @move_frequency = 0
        @move_speed = 0
        @hp = maxhp
        @sp = maxsp
        @troop = nil
      end
      #--------------------------------------------------------------------
      # * Enemy Artificial Intelligence
      #--------------------------------------------------------------------
      # Handles the enemy's decision making and priorities.
      #--------------------------------------------------------------------
      def check_ai
        check_status
        return true if check_self_status
        return true if check_troop_status
        return false unless @engaged
        return true if check_range_spell if @hp < (maxhp/25)
        return true if check_melee_attack
        return true if check_range_spell unless @hp < (maxhp/25)
        @guarding = (1 == rand(5))
        return @guarding
      end
      #--------------------------------------------------------------------
      def set_skills(kind = 1)
        skills = []
        for action in $data_enemies[@enemy_id].actions
          skills.push($data_skills[action.skill_id]) if action.kind == kind
        end
        return skills
      end
      #--------------------------------------------------------------------
      def check_self_status
        if @hp < (maxhp/25)
          skills = set_skills(1)
          return false if skills.size == 0 or skills == []
          for skill in skills
            next if !skill_can_use?(skill.id)
            next unless [3, 4, 7].include?(skill.scope) and skill.power < 0
            case skill.scope
            when 3,7
              target_enemies = [self]
            when 4
              target_enemies = []
              for enemy in $ABS.enemies.values
                target_enemies.push(enemy) if enemy.troop == @troop and
                  $ABS.check_range($game_map.events[@event_id], $game_map.events[enemy.event_id], skill.range)
              end
            end
            for target in target_enemies
              target.skill_effect(self, skill)
              sprite = nil
              for spr in $scene.spriteset.character_sprites
                sprite = spr if spr.character == $game_map.events[target.event_id]
              end
              sprite.damage(target.damage, target.critical) if sprite
            end
            successful_hit(self, target_enemies, skill) unless target_enemies == nil
            event = $game_map.events[@event_id]
            $ABS.animate(event, event.page.graphic.character_name + '-cast',
              event.direction/2, 4, 3, 0) if $ABS.e_animations
            return true
          end
          return false
        end
      end
      #--------------------------------------------------------------------
      def check_troop_status
        skills = set_skills(1)
        return false if skills.size == 0 or skills == []
        troop = []
        for enemy in $ABS.enemies.values
          troop.push(enemy) if enemy.troop == @troop and (enemy.hp <
            (enemy.maxhp*0.25)) and enemy != self
        end
        return false if troop.size == 0 or troop == []
        for skill in skills
          next if !skill_can_use?(skill.id)
          next unless [3, 4].include?(skill.scope) and skill.power < 0
          case skill.scope
          when 3
            top_target = self
            for target in troop
              top_target = target if target.hp < top_target.hp and
                $ABS.check_range($game_map.events[@event_id], $game_map.events[target.event_id], skill.range)
            end
            target_enemies = [top_target]
          when 4
            target_enemies = []
            for target in troop
              target_enemies.push(target) if $ABS.check_range($game_map.events[@event_id], $game_map.events[target.event_id], skill.range)
            end
          end
          for target in target_enemies
            target.skill_effect(self, skill)
            sprite = nil
            for spr in $scene.spriteset.character_sprites
              sprite = spr if spr.character == $game_map.events[target.event_id]
            end
            sprite.damage(target.damage, target.critical) if sprite
          end
          successful_hit(self, target_enemies, skill) unless target_enemies == nil
          event = $game_map.events[@event_id]
          $ABS.animate(event, event.page.graphic.character_name + '-cast',
            event.direction/2, 4, 3, 0) if $ABS.e_animations
          return true
        end
        return false
      end
      #------------------------------------------------------------------------
      def check_melee_attack
        if $ABS.check_range(self, $game_player, 1) and
            $ABS.check_facing(self, $game_player) and @cooldown == 0
          event = $game_map.events[@event_id]
          $ABS.animate(event, event.page.graphic.character_name + '-atk',
            event.direction/2, 4, 3, 0) if $ABS.e_animations
          $ABS.player.attack_effect(self)
          sprite = nil
          for spr in $scene.spriteset.character_sprites
            sprite = spr if spr.character == $game_player
          end
          sprite.damage($ABS.player.damage, $ABS.player.critical) if sprite
          if $ABS.player.damage != 'Miss' and $ABS.player.damage != 0
            successful_hit(self, [$ABS.player])
          end
          return true
        end
        return false
      end
      #------------------------------------------------------------------------
      def check_range_spell
        skills = set_skills(1)
        return false if skills.size == 0 or skills == []
        viable_skills = []
        for skill in skills
          next if !skill_can_use?(skill.id)
          next unless $ABS.check_range($game_map.events[@event_id], $game_player, skill.range)
          next unless [1, 2].include?(skill.scope) or skill.power >= 0
          viable_skills.push(skill)
        end
        return false if viable_skills.size == 0 or viable_skills == []
        skill = viable_skills[rand(viable_skills.size+1)]
        return false if skill == nil
        $ABS.player.skill_effect(self, skill)
        event = $game_map.events[@event_id]
        $ABS.animate(event, event.page.graphic.character_name + '-cast',
          event.direction/2, 4, 3, 0) if $ABS.e_animations
        sprite = nil
          for spr in $scene.spriteset.character_sprites
            sprite = spr if spr.character == $game_player
          end
          sprite.damage($ABS.player.damage, $ABS.player.critical) if sprite
        successful_hit(self, [$ABS.player], skill)
        return true
      end 
      #------------------------------------------------------------------------
      def reset
        @cooldown = ((Graphics.frame_rate * ((500 + (999 - agi)*1.2) / 1000)) * 1.5).floor
      end
      #------------------------------------------------------------------------
      def chill
        @cooldown -= 1 unless @cooldown == 0
      end
      #------------------------------------------------------------------------
      def find_player
        if $ABS.check_range(self, $game_player, 7) and
            $ABS.check_facing(self, $game_player)
          engage unless @engaged
          return
        end
        check_disengage if @engaged
        return
      end
      #------------------------------------------------------------------------
      def guarding?
        return @guarding
      end
      #------------------------------------------------------------------------
      def successful_hit(object = self, target = [$game_party.actors[0]], skill = nil)
        anim1 = 0; anim2 = 0
        if skill == nil
          anim1 = animation1_id if !$ABS.p_animations
          anim2 = animation2_id
        else
          anim1 = skill.animation1_id if !$ABS.p_animations
          anim2 = skill.animation2_id
        end
        if object.is_a?(Game_Actor)
          $game_player.animation_id = anim1 if !$ABS.p_animations
        else
          event = $game_map.events[object.event_id]
          event.animation_id = anim1 if !$ABS.e_animations
        end
        return if !target
        for tar in target
          next if !tar
          if tar.is_a?(Game_Actor)
            $game_player.animation_id = anim2
            $ABS.animate($game_player, $game_player.character_name + '-hit',
              $game_player.direction/2, 4, 3) if $ABS.p_animations
          else
            event = $game_map.events[tar.event_id]
            event.animation_id = anim2
            $ABS.animate(event, event.page.graphic.character_name + '-hit',
              event.direction/2, 4, 3, 0) if $ABS.e_animations
          end
        end
      end
      #------------------------------------------------------------------------
      def engage
        @engaged = true
        engage_troops
        @dis_cooldown = 500
        reset
        event = $game_map.events[@event_id]
        @move_type = event.move_type
        @move_frequency = event.move_frequency
        @move_speed = event.move_speed
        event.move_type = 2
        event.move_frequency = 5
        event.move_speed = 5
      end
      #------------------------------------------------------------------------
      def engage_troops
        for enemy in $ABS.enemies.values
          if enemy.troop == @troop
            enemy.engage unless enemy.engaged
          end
        end
      end
      #------------------------------------------------------------------------
      def disengage
        @engaged = false
        event = $game_map.events[@event_id]
        event.move_type = @move_type
        event.move_frequency = @move_frequency
        event.move_speed = @move_speed
      end
      #------------------------------------------------------------------------
      def check_disengage
        @dis_cooldown -= 1
        if @dis_cooldown == 0
          disengage
        end
      end
      #------------------------------------------------------------------------
      def check_status
        if hp < (maxhp / 25)
          event = $game_map.events[@event_id]
          event.move_type = 4
          event.move_frequency = 5
          event.move_speed = 5
        else
          event = $game_map.events[@event_id]
          event.move_type = 2
          event.move_frequency = 5
          event.move_speed = 5
        end
      end
      #------------------------------------------------------------------------
      def path_find
        return if $game_map.events[@event_id].runpath
        $game_map.events[@event_id].find_object($game_player)
      end
      #------------------------------------------------------------------------
      def id
        return @enemy_id
      end
      #------------------------------------------------------------------------
      def name
        return $data_enemies[@enemy_id].name
      end
      #------------------------------------------------------------------------
      def base_maxhp
        return $data_enemies[@enemy_id].maxhp
      end
      #------------------------------------------------------------------------
      def base_maxsp
        return $data_enemies[@enemy_id].maxsp
      end
      #------------------------------------------------------------------------
      def base_str
        return $data_enemies[@enemy_id].str
      end
      #------------------------------------------------------------------------
      def base_dex
        return $data_enemies[@enemy_id].dex
      end
      #------------------------------------------------------------------------
      def base_agi
        return $data_enemies[@enemy_id].agi
      end
      #------------------------------------------------------------------------
      def base_int
        return $data_enemies[@enemy_id].int
      end
      #------------------------------------------------------------------------
      def base_atk
        return $data_enemies[@enemy_id].atk
      end
      #------------------------------------------------------------------------
      def base_pdef
        return $data_enemies[@enemy_id].pdef
      end
      #------------------------------------------------------------------------
      def base_mdef
        return $data_enemies[@enemy_id].mdef
      end
      #------------------------------------------------------------------------
      def base_eva
        return $data_enemies[@enemy_id].eva
      end
      #------------------------------------------------------------------------
      def animation1_id
        return $data_enemies[@enemy_id].animation1_id
      end
      #------------------------------------------------------------------------
      def animation2_id
        return $data_enemies[@enemy_id].animation2_id
      end
      #------------------------------------------------------------------------
      def element_rate(element_id)
        table = [0,200,150,100,50,0,-100]
        result = table[$data_enemies[@enemy_id].element_ranks[element_id]]
        for i in @states
          result /= 2 if $data_states[i].guard_element_set.include?(element_id)
        end
        return result
      end
      #------------------------------------------------------------------------
      def state_ranks
        return $data_enemies[@enemy_id].state_ranks
      end
      #------------------------------------------------------------------------
      def state_guard?(state_id)
        return false
      end
      #------------------------------------------------------------------------
      def element_set
        return []
      end
      #------------------------------------------------------------------------
      def plus_state_set
        return []
      end
      #------------------------------------------------------------------------
      def minus_state_set
        return []
      end
      #------------------------------------------------------------------------
      def actions
        return $data_enemies[@enemy_id].actions
      end
      #------------------------------------------------------------------------
      def exp
        return $data_enemies[@enemy_id].exp
      end
      #------------------------------------------------------------------------
      def gold
        return $data_enemies[@enemy_id].gold
      end
      #------------------------------------------------------------------------
      def item_id
        return $data_enemies[@enemy_id].item_id
      end
      #------------------------------------------------------------------------
      def weapon_id
        return $data_enemies[@enemy_id].weapon_id
      end
      #------------------------------------------------------------------------
      def armor_id
        return $data_enemies[@enemy_id].armor_id
      end
      #------------------------------------------------------------------------
      def treasure_prob
        return $data_enemies[@enemy_id].treasure_prob
      end
    end # End ABS::Enemy Class
  end # End ABS Class
  
  #------------------------------------------------------------------------
  # * Game Actor ABS Clsas
  #------------------------------------------------------------------------
  # This is how the Player interacts with enemies and hotkeys
  #------------------------------------------------------------------------
  class Game_Actor
    attr_accessor :abs
    #------------------------------------------------------------------------
    alias prexus_abs_g_actor_setup setup
    #------------------------------------------------------------------------
    def setup(actor_id)
      prexus_abs_g_actor_setup(actor_id)
      @abs = Game_Actor::ABS.new # Setup the ABS class
    end
    #------------------------------------------------------------------------
    class ABS
      attr_accessor :cooldown
      attr_accessor :acted
      attr_accessor :hot_key
      #----------------------------------------------------------------------
      def initialize
        @cooldown = 0 # Attacking/casting cooldown
        @acted = false # Flag for whether or not you've acted recently
        @hot_key = [nil, nil, nil] # Hot key array
      end
      #----------------------------------------------------------------------
      # * Cooldown/input methods
      #----------------------------------------------------------------------
      def chill
        @cooldown -= 1 if @acted and @cooldown != 0
      end
      #----------------------------------------------------------------------
      def reset
        @cooldown = ((Graphics.frame_rate * ((500 + (999 - $game_party.actors[0].agi)*1.2) / 1000)) * 1.5).floor / 2 unless @acted
      end
      #----------------------------------------------------------------------
      # * Attacking/Spell Casting Methods
      #----------------------------------------------------------------------
      def attack
        # Animate Actor:
        $ABS.animate($game_player, $game_player.character_name + '-atk',
          $game_player.direction/2, 4, 3) if $ABS.p_animations
        $game_player.animation_id = $ABS.player.animation1_id unless $ABS.p_animations
        for enemy in $ABS.enemies.values
          next if !$ABS.check_range($game_player, enemy, 1) # If enemy is in range
          next if !$ABS.check_facing($game_player, enemy) # and not behind
          enemy.attack_effect($ABS.player) # hit the enemy
          event = $game_map.events[enemy.event_id]
          sprite = nil
          for spr in $scene.spriteset.character_sprites
            sprite = spr if spr.character == event
          end
          sprite.damage(enemy.damage, enemy.critical) if sprite # show damage
          if enemy.damage != 'Miss' and enemy.damage != 0 # if the attack hit
            # Animate Enemy:
            $ABS.animate(event, event.page.graphic.character_name + '-hit',
              event.direction/2, 4, 3, 0) if $ABS.e_animations
            event.animation_id = $ABS.player.animation2_id
          end
          @acted = true # Yes you've recently attacked!
        end
      end
      #----------------------------------------------------------------------
      def cast(skill)
        return unless skill
        skill = $data_skills[skill]
        return unless skill or $ABS.player.skill_can_use?(skill.id) # Can use?
        return if $ABS.player.sp < skill.sp_cost # We sure about that?
        @acted = true # Then you've acted!
        reset # Reset the cooldown for some reason
        # Animate Actor:
        $game_player.animation_id = skill.animation1_id
        $ABS.animate($game_player, $game_player.character_name + '-cast',
          $game_player.direction/2, 4, 3, 0) if $ABS.p_animations
        # Deal with SP
        $ABS.player.sp -= skill.sp_cost
        case skill.scope
        when 1 # One Enemy
          target = find_single_target(skill) # Find closest enemy
          return unless target # If you found a valid enemy
          target.skill_effect($ABS.player, skill) # Hit enemy
          event = $game_map.events[target.event_id]
          sprite = nil
          for spr in $scene.spriteset.character_sprites
            sprite = spr if spr.character == event
          end
          sprite.damage(target.damage, target.critical) if sprite # Show damage
          # Animate Enemy:
          event.animation_id = skill.animation2_id
          $ABS.animate(event, event.page.graphic.character_name + '-hit',
              event.direction/2, 4, 3, 0) if $ABS.e_animations
        when 2 # Multiple Enemies
          target = find_all_target(skill) # Find all enemies in range
          return unless target # If you found valid enemies
          for tar in target # For all the enemies:
            tar.skill_effect($ABS.player, skill) # Hit enemy
            event = $game_map.events[tar.event_id]
            sprite = nil
            for spr in $scene.spriteset.character_sprites
              sprite = spr if spr.character == event
            end
            sprite.damage(tar.damage, tar.critical) if sprite # Show damage
            # Animate Enemy:
            event.animation_id = skill.animation2_id
            $ABS.animate(event, event.page.graphic.character_name + '-hit',
              event.direction/2, 4, 3, 0) if $ABS.e_animations
          end
        when 3..4,7 # For yourself
          $ABS.player.skill_effect($ABS.player, skill) # Hit yourself
          sprite = nil
          for spr in $scene.spriteset.character_sprites
            sprite = spr if spr.character == $game_player
          end
          sprite.damage($ABS.player.damage, $ABS.player.critical) if sprite # Show heal
          # Animate self:
          $game_player.animation_id = skill.animation2_id
        else
          return
        end
      end
      #----------------------------------------------------------------------
      # * Target Finding Methods
      #----------------------------------------------------------------------
      def find_single_target(skill)
        targets = [] # Holds the valid targets
        target_range = []  # Holds their range from player
        final_targets = [] # Holds final targets (only valids)
        for enemy in $ABS.enemies.values
          next if !$ABS.check_range($game_player, enemy, skill.range) # If in range
          next if !$ABS.check_facing($game_player, enemy) # If player can see
          targets.push(enemy) # Shove the enemy
          target_range.push($ABS.find_range($game_player, enemy)) # Shove his range
        end
        big_range = 0 # Lowest Range from Player
        for i in target_range # Finding the lowest range of valid targets
          big_range = i if i > big_range 
        end
        for i in 0...targets.size # Finding the targets inside that range
          final_targets.push(targets[i]) if target_range[i] <= big_range
        end
        random = rand(final_targets.size)-1 # Selecting one of the targets
        random = 0 if random < 0
        return final_targets[random] # Return that target
      end
      #----------------------------------------------------------------------
      def find_all_target(skill)
        targets = [] # All Targets
        for enemy in $ABS.enemies.values
          next if !$ABS.check_range($game_player, enemy, skill.range) # If in range
          next if !$ABS.check_facing($game_player, enemy) # If player can see
          targets.push(enemy) # Shove enemy
        end
        return targets # Return all enemies
      end
    end
  end
#--------------------------------------------------------------------------
# * End SDK Enable Test
#--------------------------------------------------------------------------
  
end # End SDK Check

#==============================================================================
# ** Prexus ABS
#------------------------------------------------------------------------------
# Prexus
# Version 1 Final  Build
# 18.12.05
#==============================================================================

#--------------------------------------------------------------------------
# * Begin SDK Enable Test
#--------------------------------------------------------------------------
if SDK.state('Prexus ABS') == true
  
  class Game_Map
    alias prexus_abs_g_map_setup setup
    def setup(map_id)
      prexus_abs_g_map_setup(map_id)
      $ABS = ABS.new if !$ABS
      $ABS.setup_enemies(@events)
    end
  end
  #--------------------------------------------------------------------------
  class Scene_Map
    attr_accessor :spriteset
    alias prexus_abs_s_map_update update
    def update
      $ABS.update if $ABS.enabled
      if !$ABS.player.abs.acted and !$game_party.actors[0].guarding? and $ABS.enabled
        $ABS.player.abs.attack if Input.trigger?(Input::A) and $ABS.player.weapon_id > 0
        $ABS.player.abs.cast($ABS.player.abs.hot_key[0]) if  Input.trigger?(Input::X)
        $ABS.player.abs.cast($ABS.player.abs.hot_key[1]) if  Input.trigger?(Input::Y)
        $ABS.player.abs.cast($ABS.player.abs.hot_key[2]) if  Input.trigger?(Input::Z)
      end
      prexus_abs_s_map_update
    end
  end
  #--------------------------------------------------------------------------
  class Game_Actor
    #------------------------------------------------------------------------
    def guarding?
      return true if Input.press?(Input::L)
      return false
    end
  end
  #--------------------------------------------------------------------------
  class Game_Event
    attr_reader :page
    attr_reader :map_id
    def name
      return @event.name
    end
  end
  #--------------------------------------------------------------------------
  class Game_Character
    attr_accessor :move_type
    attr_accessor :move_frequency
    attr_accessor :move_speed
    attr_accessor :character_name
    attr_accessor :wait
    attr_accessor :old_chr_name
    attr_accessor :old_dir
    attr_accessor :animating
    #------------------------------------------------------------------------
    alias animation_engine_game_character_initialize initialize
    #------------------------------------------------------------------------
    def initialize
      animation_engine_game_character_initialize
      @animating = false
      @wait = false
      @old_chr_name = @character_name
      @old_dir = @direction
    end
    #------------------------------------------------------------------------
    def animate(animation_name, position, frames, wait, repeat)
      @character_name = animation_name if @animating == false
      @pattern = 0
      @count = 0
      @repeat = repeat
      @direction_fix = true
      @old_dir = @direction
      @direction = position * 2
      @frames = frames
      lock
      @animating = true
      @wait = wait
      @anim_wait_count = @wait
      update
      return
    end
    #------------------------------------------------------------------------
    def update_animate
      if @anim_wait_count > 0
        @anim_wait_count -= 1
        return
      end
      if @pattern >= @frames or moving?
        if !moving?
          if @count < @repeat
            @pattern = 0
            @count += 1
            @anim_wait_count = @wait
            update
            return
          end
        end
        unlock
        @animating = false
        @pattern = 0
        @direction_fix = false
        @direction = @old_dir
        if self.is_a?(Game_Event)
          @character_name = @page != nil ? @page.graphic.character_name : ''
        else
          @character_name = @old_chr_name
        end
        $game_player.refresh
        $game_map.refresh
        return
      end
      @pattern += 1
      @anim_wait_count = @wait
      update
    end
    #------------------------------------------------------------------------
    def update_movement_type
      if @animating == true
        update_animate
        return
      end
      if jumping?
        update_jump
      elsif moving?
        update_move
      else
        update_stop
      end
    end
    #------------------------------------------------------------------------
    def update_movement
      if @stop_count > (40 - @move_frequency * 2) * (6 - @move_frequency)
        case @move_type
        when 1 # Random
          move_type_random
        when 2
          if @runpath
            run_path
          else
            move_type_toward_player
          end
        when 3
          move_type_custom
        when 4
          move_type_escape_player
        end
      end
    end
    #------------------------------------------------------------------------
    # * Move Type : Escape
    #------------------------------------------------------------------------
    def move_type_escape_player
      sx = @x - $game_player.x
      sy = @y - $game_player.y
      abs_sx = sx > 0 ? sx : -sx
      abs_sy = sy > 0 ? sy : -sy
      if sx + sy >= 20
        move_random
        return
      end
      move_away_from_player
    end
    #------------------------------------------------------------------------
    # * Move Type : Approach
    #------------------------------------------------------------------------
    def move_type_toward_player
      sx = @x - $game_player.x
      sy = @y - $game_player.y
      abs_sx = sx > 0 ? sx : -sx
      abs_sy = sy > 0 ? sy : -sy
      if sx + sy >= 20
        move_random
        return
      end
      move_toward_player
    end
    #------------------------------------------------------------------------
    # * Move away from Player
    #------------------------------------------------------------------------
    def move_away_from_player
      sx = @x - $game_player.x
      sy = @y - $game_player.y
      if sx == 0 and sy == 0
        return
      end
      abs_sx = sx.abs
      abs_sy = sy.abs
      if abs_sx == abs_sy
        rand(2) == 0 ? abs_sx += 1 : abs_sy += 1
      end
      if abs_sx > abs_sy
        sx > 0 ? move_right : move_left
        if not moving?
          rand(2) == 1 ? move_down : move_up
        end
      else
        sy > 0 ? move_down : move_up
        if not moving?
          rand(2) == 1 ? move_right : move_left
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  class Game_Battler
    def skill_can_use?(skill_id)
      if $data_skills[skill_id].sp_cost > self.sp
        return false
      end
      if dead?
        return false
      end
      if $data_skills[skill_id].atk_f == 0 and self.restriction == 1
        return false
      end
      occasion = $data_skills[skill_id].occasion
      if $scene.is_a?(Scene_Map)
        return (occasion == 0 or occasion == 1)
      else
        return (occasion == 0 or occasion == 2)
      end
    end
    def skill_effect(user, skill)
      self.critical = false
      if ((skill.scope == 3 or skill.scope == 4) and self.hp == 0) or
         ((skill.scope == 5 or skill.scope == 6) and self.hp >= 1)
        return false
      end
      effective = false
      effective |= skill.common_event_id > 0
      hit = skill.hit
      if skill.atk_f > 0
        hit *= user.hit / 100
      end
      hit_result = (rand(100) < hit)
      effective |= hit < 100
      if hit_result == true
        power = skill.power + user.atk * skill.atk_f / 100
        if power > 0
          power -= self.pdef * skill.pdef_f / 200
          power -= self.mdef * skill.mdef_f / 200
          power = [power, 0].max
        end
        rate = 20
        rate += (user.str * skill.str_f / 100)
        rate += (user.dex * skill.dex_f / 100)
        rate += (user.agi * skill.agi_f / 100)
        rate += (user.int * skill.int_f / 100)
        self.damage = power * rate / 20
        self.damage *= elements_correct(skill.element_set)
        self.damage /= 100
        if self.damage > 0
          if self.guarding?
            self.damage /= 2
          end
        end
        if skill.variance > 0 and self.damage.abs > 0
          amp = [self.damage.abs * skill.variance / 100, 1].max
          self.damage += rand(amp+1) + rand(amp+1) - amp
        end
        eva = 8 * self.agi / user.dex + self.eva
        hit = self.damage < 0 ? 100 : 100 - eva * skill.eva_f / 100
        hit = self.cant_evade? ? 100 : hit
        hit_result = (rand(100) < hit)
        effective |= hit < 100
      end
      if hit_result == true
        if skill.power != 0 and skill.atk_f > 0
          remove_states_shock
          effective = true
        end
        last_hp = self.hp
        self.hp -= self.damage
        effective |= self.hp != last_hp
        @state_changed = false
        effective |= states_plus(skill.plus_state_set)
        effective |= states_minus(skill.minus_state_set)
        if skill.power == 0
          self.damage = ""
          unless @state_changed
            self.damage = "Miss"
          end
        end
      else
        self.damage = "Miss"
      end
      return effective
    end
  end
  #--------------------------------------------------------------------------
  class Scene_Skill
    alias prexus_abs_s_skill_update update
    def update
      if Input.trigger?(Input::X)
        skill = @skill_window.skill
        unless $ABS.player.abs.hot_key[0] or 
               $ABS.player.abs.hot_key.include?(skill.id)
          $ABS.player.abs.hot_key[0] = skill.id
        end
        @skill_window.refresh
        return
      end
      if Input.trigger?(Input::Y)
        skill = @skill_window.skill
        unless $ABS.player.abs.hot_key[1] or 
               $ABS.player.abs.hot_key.include?(skill.id)
          $ABS.player.abs.hot_key[1] = skill.id
        end
        @skill_window.refresh
        return
      end
      if Input.trigger?(Input::Z)
        skill = @skill_window.skill
        unless $ABS.player.abs.hot_key[2] or 
               $ABS.player.abs.hot_key.include?(skill.id)
          $ABS.player.abs.hot_key[2] = skill.id
        end
        @skill_window.refresh
        return
      end
      if Input.trigger?(Input::A)
        skill = @skill_window.skill
        for i in 0..$ABS.player.abs.hot_key.size
          skillX = $ABS.player.abs.hot_key[i]
          next unless skillX
          $ABS.player.abs.hot_key[i] = nil if skill.id == skillX
        end
        @skill_window.refresh
        return
      end
      prexus_abs_s_skill_update
    end
  end
  #--------------------------------------------------------------------------
  class Window_Skill < Window_Selectable
    def draw_item(index)
      skill = @data[index]
      if @actor.skill_can_use?(skill.id)
        if $ABS.player.abs.hot_key.include?(skill.id)
          self.contents.font.color = Color.new(0, 225, 0, 255)
        else
          self.contents.font.color = normal_color
        end
      else
        if $ABS.player.abs.hot_key.include?(skill.id)
          self.contents.font.color = Color.new(0, 225, 0, 160)
        else
          self.contents.font.color = disabled_color
        end
      end
      x = 4 + index % 2 * (288 + 32)
      y = index / 2 * 32
      rect = Rect.new(x, y, self.width / @column_max - 32, 32)
      self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
      bitmap = RPG::Cache.icon(skill.icon_name)
      opacity = self.contents.font.color == normal_color ? 255 : 128
      self.contents.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
      self.contents.draw_text(x + 28, y, 204, 32, skill.name, 0)
      self.contents.draw_text(x + 232, y, 48, 32, skill.sp_cost.to_s, 2)
    end
  end
  #--------------------------------------------------------------------------
  class Scene_Map
    alias prex_abs_s_map_transfer_player transfer_player
    def transfer_player
      for i in 0...$game_map.events.size
        event = $ABS.events[i]
        trigger = $ABS.event_triggers[i]
        next unless event and trigger
        if ['A', 'B', 'C', 'D'].include?(trigger.upcase)
          key = [event.map_id, event.id, trigger]
          $game_self_switches[key] = false
          $ABS.events.delete(event)
          $ABS.event_triggers.delete(trigger)
          next
        end
        if trigger.upcase == 'CHEST'
          key = [event.map_id, event.id, 'A']
          $game_self_switches[key] = false
          key = [event.map_id, event.id, 'B']
          $game_self_switches[key] = false
          key = [event.map_id, event.id, 'C']
          $game_self_switches[key] = false
          key = [event.map_id, event.id, 'D']
          $game_self_switches[key] = false
          $ABS.events.delete(event)
          $ABS.event_triggers.delete(trigger)
          next
        end
      end
      prex_abs_s_map_transfer_player
    end
  end
  #--------------------------------------------------------------------------
  class Scene_Save < Scene_File
    alias prex_abs_s_save_write_data write_data
    def write_data(file)
      prex_abs_s_save_write_data(file)
      Marshal.dump($ABS, file)
    end
  end
  #--------------------------------------------------------------------------
  class Scene_Load < Scene_File
    alias prex_abs_s_load_read_data read_data
    def read_data(file)
      prex_abs_s_load_read_data(file)
      $ABS = Marshal.load(file)
    end
  end
  #--------------------------------------------------------------------------
  class Spriteset_Map
    attr_accessor :character_sprites
  end
#--------------------------------------------------------------------------
# * End SDK Enable Test
#--------------------------------------------------------------------------
  
end

#==============================================================================
# ** Prexus ABS
#------------------------------------------------------------------------------
# Prexus
# Version 1 Final Build
# 18.12.05
#==============================================================================

#--------------------------------------------------------------------------
# * Begin SDK Enable Test
#--------------------------------------------------------------------------

if SDK.state("Prexus ABS") == true

  class ABS
    attr_accessor :portrait
    alias prex_abs_abs_initialize initialize
    def initialize
      prex_abs_abs_initialize
      @p_animations = true # To play charset animations for players
      @e_animations = true # To play charset animations for enemies
      @portrait     = true # To show a portrait in HUD. If false, shows charset.
    end
  end
  #------------------------------------------------------------------------
  module RPG
    class Skill
      attr_accessor :range
      #--------------------------------------------------------------------
      # * Instructions:
      #     Add new spells and their ranges by adding these lines:
      # when "SpellName"
      #   @range = valueforrange
      #--------------------------------------------------------------------
      #     For Example:
      # when "Cross Cut"
      #   @range = 2
      #--------------------------------------------------------------------
      def set_range
        @range = 0
        case self.name
        # Add New Lines Here:
        when "Trovão"
          @range = 10
        when "Gelasca"
          @range = 10
        when "Fogaréu"
          @range = 10
        when "Super Cura"
          @range = 10
        end
      end
    end
  end
  #------------------------------------------------------------------------
  class Scene_Title
    alias prexus_abs_s_title_main_database main_database
    def main_database
      prexus_abs_s_title_main_database
      $data_skills.each {|s| s.set_range if s}
    end
  end
  #------------------------------------------------------------------------
  module RPG
    class Sprite < ::Sprite
      def damage(value, critical)
        dispose_damage
        if value.is_a?(Numeric)
          damage_string = value.abs.to_s
        else
          damage_string = value.to_s
        end
        bitmap = Bitmap.new(160, 48)
        bitmap.font.name = "Arial Black"
        bitmap.font.size = 16
        if value.is_a?(Numeric) and value < 0
          bitmap.font.color.set(0, 96, 0)
        elsif value.is_a?(Numeric) and value > 0
          bitmap.font.color.set(96, 0, 0)
        else
          bitmap.font.color.set(0, 0, 96)
        end
        bitmap.draw_text(-1, 12-1, 160, 36, damage_string, 1)
        bitmap.draw_text(+1, 12-1, 160, 36, damage_string, 1)
        bitmap.draw_text(-1, 12+1, 160, 36, damage_string, 1)
        bitmap.draw_text(+1, 12+1, 160, 36, damage_string, 1)
        if value.is_a?(Numeric) and value < 0
          bitmap.font.color.set(0, 255, 0)
        elsif value.is_a?(Numeric) and value > 0
          bitmap.font.color.set(255, 0, 0)
        else
          bitmap.font.color.set(0, 0, 255)
        end
        bitmap.draw_text(0, 12, 160, 36, damage_string, 1)
        if critical
          bitmap.font.color.set(96, 96, 0)
          bitmap.draw_text(-1, -1, 160, 20, "Nice!", 1)
          bitmap.draw_text(+1, -1, 160, 20, "Nice!", 1)
          bitmap.draw_text(-1, +1, 160, 20, "Nice!", 1)
          bitmap.draw_text(+1, +1, 160, 20, "Nice!", 1)
          bitmap.font.color.set(255, 255, 0)
          bitmap.draw_text(0, 0, 160, 20, "Nice!", 1)
        end
        @_damage_sprite = ::Sprite.new(self.viewport)
        @_damage_sprite.bitmap = bitmap
        @_damage_sprite.ox = 80
        @_damage_sprite.oy = 20
        @_damage_sprite.x = self.x
        @_damage_sprite.y = self.y - self.oy / 2
        @_damage_sprite.z = 3000
        @_damage_duration = 40
      end
    end
  end

#--------------------------------------------------------------------------
# * End SDK Enable Test
#--------------------------------------------------------------------------

end

#==============================================================================
# ** Prexus ABS
#------------------------------------------------------------------------------
# Prexus
# Version 1 Final Build
# 18.12.05
#==============================================================================

#--------------------------------------------------------------------------
# * Begin SDK Enable Test
#--------------------------------------------------------------------------

if SDK.state("Prexus ABS") == true
  
  class Scene_Map
    attr_accessor :hud_window
    alias prex_abshud_s_map_main main
    def main
      @hud_window = ABS::Window_Hud.new
      prex_abshud_s_map_main
    end
    alias prex_abshud_s_map_update update
    def update
      prex_abshud_s_map_update
      if Input.trigger?(Input::R)
        @hud_window.visible = !@hud_window.visible if $ABS.enabled
      end
      @hud_window.visible = false if !$ABS.enabled
      @hud_window.update
    end
  end
  #---------------------------------------------------------------------------
  class ABS
    class Window_Hud < Window_Base
      attr_accessor :portrait
      def initialize
        super(-16, -16, 672, 512)
        self.contents = Bitmap.new(width - 32, height - 32)
        self.contents.font.name = "Georgia"
        self.contents.font.bold = true
        self.contents.font.size = 14
        self.opacity = 0
        @hp = 0
        @maxhp = 0
        @sp = 0
        @maxsp = 0
        @portrait = nil
        refresh
      end
      #------------------------------------------------------------------------
      def refresh
        self.contents.clear
        @hp = $game_party.actors[0].hp
        @maxhp = $game_party.actors[0].maxhp
        @sp = $game_party.actors[0].sp
        @maxsp = $game_party.actors[0].maxsp
        #---------------------------------------------------------------------
        # * Draw HUD Background (will adjust to any size image)
        # - Image is ..\Graphic\HUD\Background.png
        #---------------------------------------------------------------------
        bitmap = RPG::Cache.hud("Background")
        self.contents.blt(640-bitmap.width, 480-bitmap.height, bitmap,
                          Rect.new(0, 0, bitmap.width, bitmap.height))
        #---------------------------------------------------------------------
        # * Draw HP and SP Bars and Text
        #---------------------------------------------------------------------
        hpp = (@hp.to_f / @maxhp) * 100
        @x = 640-152
        @y = 480-40
        self.contents.fill_rect(@x+0, @y+9 , 102, 8, Color.new(143,  17,  17, 180))
        self.contents.fill_rect(@x+1, @y+10, 100, 6, Color.new(120,  60,  60, 180))
        self.contents.fill_rect(@x+1, @y+10, hpp, 2, Color.new(234, 195, 195, 180))
        self.contents.fill_rect(@x+1, @y+12, hpp, 2, Color.new(217, 152, 152, 180))
        self.contents.fill_rect(@x+1, @y+14, hpp, 2, Color.new(181,  75,  75, 180))
        text = "#{@hp}/#{@maxhp}"
        width  = self.contents.text_size(text).width
        height = self.contents.text_size(text).height
        self.contents.font.color = Color.new(  0,   0,   0)
        self.contents.draw_text(@x+102 - width, @y+1, width, height, text)
        self.contents.font.color = Color.new(255, 255, 255)
        self.contents.draw_text(@x+101 - width, @y+0, width, height, text)
        spp = (@sp.to_f / @maxsp) * 100
        self.contents.fill_rect(@x+0, @y+25, 102, 8, Color.new( 17,  79, 143, 180))
        self.contents.fill_rect(@x+1, @y+26, 100, 6, Color.new( 60,  60, 120, 180))
        self.contents.fill_rect(@x+1, @y+26, spp, 2, Color.new(196, 213, 234, 180))
        self.contents.fill_rect(@x+1, @y+28, spp, 2, Color.new(153, 185, 271, 180))
        self.contents.fill_rect(@x+1, @y+30, spp, 2, Color.new( 75, 127, 181, 180))
        text = "#{@sp}/#{@maxsp}"
        width  = self.contents.text_size(text).width
        height = self.contents.text_size(text).height
        self.contents.font.color = Color.new(  0,   0,   0)
        self.contents.draw_text(@x+102 - width, @y+18, width, height, text)
        self.contents.font.color = Color.new(255, 255, 255)
        self.contents.draw_text(@x+101 - width, @y+17, width, height, text)
        #---------------------------------------------------------------------
        # * Draw Face Graphic
        # - Face Graphics found in ..\Graphics\HUD\portraits\
        #   Must match hero's name!
        #---------------------------------------------------------------------
        if $ABS.portrait
          bitmap = RPG::Cache.portrait($game_party.actors[0].name.to_s)
          self.contents.blt(@x+16, @y-(bitmap.height), bitmap,
                            Rect.new(0, 0, bitmap.width, bitmap.height))
        else
          draw_actor_graphic($ABS.player, @x+64, @y)
        end
        #---------------------------------------------------------------------
        # * Draw Skill Graphics
        #---------------------------------------------------------------------
        for i in 0..$ABS.player.abs.hot_key.size
          next unless $ABS.player.abs.hot_key[i]
          skill = $data_skills[$ABS.player.abs.hot_key[i]]
          next unless skill
          bitmap = RPG::Cache.icon(skill.icon_name)
          self.contents.blt(@x+114, @y-56+(i*32), bitmap, Rect.new(0, 0, 24, 24))
          self.contents.font.color = Color.new(0,0,0)
          self.contents.draw_text(@x+115, @y-55+(i*32), 16, 12, "x") if i==0
          self.contents.draw_text(@x+115, @y-55+(i*32), 16, 12, "y") if i==1
          self.contents.draw_text(@x+115, @y-55+(i*32), 16, 12, "z") if i==2
          self.contents.font.color = $ABS.player.sp >= skill.sp_cost ?
                                       normal_color : Color.new(255,0,0)
          self.contents.draw_text(@x+114, @y-56+(i*32), 16, 12, "x") if i==0
          self.contents.draw_text(@x+114, @y-56+(i*32), 16, 12, "y") if i==1
          self.contents.draw_text(@x+114, @y-56+(i*32), 16, 12, "z") if i==2
        end
      end
      #-----------------------------------------------------------------------
      def update
        refresh unless (@hp == $game_party.actors[0].hp and
                        @maxhp == $game_party.actors[0].maxhp and
                        @sp == $game_party.actors[0].sp and
                        @maxsp == $game_party.actors[0].maxsp)
      end
    end
  end
  #---------------------------------------------------------------------------
  module RPG
    module Cache
      def self.portrait(filename)
        self.load_bitmap("Graphics/HUD/portraits/", filename)
      end
      def self.hud(filename)
        self.load_bitmap("Graphics/HUD/", filename)
      end
    end
  end

#--------------------------------------------------------------------------
# * End SDK Enable Test
#--------------------------------------------------------------------------

end

#==============================================================================
#   ■ Path Finding
#   By: Near Fantastica
#   Date: 24.09.05
#   Version: 1
#
#   Player :: $game_player.find_path(x,y)
#   Event Script Call :: self.event.find_path(x,y)
#   Event Movement Script Call :: self.find_path(x,y)
#==============================================================================

class Game_Character
  #--------------------------------------------------------------------------
  alias pf_game_character_initialize initialize
  alias pf_game_character_update update
  #--------------------------------------------------------------------------
  attr_accessor :map
  attr_accessor :runpath
  #--------------------------------------------------------------------------
  def initialize
    pf_game_character_initialize
    @map = nil
    @runpath = false
    @object = nil
  end
  #--------------------------------------------------------------------------
  def run_path
    return if moving?
    step = @map[@x,@y]
    @count += 1 if @object
    if @object and @count == 4
      find_object(@object)
      return
    end
    if step == 1
      @map = nil
      @runpath = false
      return
    end
    dir = rand(2)
    case dir
    when 0
      move_right if @map[@x+1,@y] == step - 1 and step != 0
      move_down if @map[@x,@y+1] == step - 1 and step != 0
      move_left if @map[@x-1,@y] == step -1 and step != 0
      move_up if @map[@x,@y-1] == step - 1 and step != 0
    when 1
      move_up if @map[@x,@y-1] == step - 1 and step != 0
      move_left if @map[@x-1,@y] == step -1 and step != 0
      move_down if @map[@x,@y+1] == step - 1 and step != 0
      move_right if @map[@x+1,@y] == step - 1 and step != 0
    end
  end
  #--------------------------------------------------------------------------
  def find_path(x,y)
    sx, sy = @x, @y
    result = setup_map(sx,sy,x,y)
    @object = nil
    @count = 0
    @runpath = result[0]
    @map = result[1]
    @map[sx,sy] = result[2] if result[2] != nil
  end
  #--------------------------------------------------------------------------
  def find_object(object)
    sx, sy = @x, @y
    result = setup_map(sx, sy, object.x, object.y)
    @object = object
    @count = 0
    @runpath = result[0]
    @map = result[1]
    @map[sx, sy] = result[2] if result[2] != nil
  end
  #--------------------------------------------------------------------------
  def setup_map(sx,sy,ex,ey)
    map = Table.new($game_map.width, $game_map.height)
    map[ex,ey] = 1
    old_positions = []
    new_positions = []
    old_positions.push([ex, ey])
    depth = 2
    depth.upto(20){|step|
      loop do
        break if old_positions[0] == nil
        x,y = old_positions.shift
        return [true, map, step] if x == sx and y+1 == sy
        if $game_player.passable?(x, y, 2) and map[x,y + 1] == 0
          map[x,y + 1] = step
          new_positions.push([x,y + 1])
        end
        return [true, map, step] if x-1 == sx and y == sy
        if $game_player.passable?(x, y, 4) and map[x - 1,y] == 0
          map[x - 1,y] = step
          new_positions.push([x - 1,y])
        end
        return [true, map, step] if x+1 == sx and y == sy
        if $game_player.passable?(x, y, 6) and map[x + 1,y] == 0
          map[x + 1,y] = step
          new_positions.push([x + 1,y])
        end
        return [true, map, step] if x == sx and y-1 == sy
        if $game_player.passable?(x, y, 8) and map[x,y - 1] == 0
          map[x,y - 1] = step
          new_positions.push([x,y - 1])
        end
      end
      old_positions = new_positions
      new_positions = []
    }
    return [false, nil, nil]
  end
end

class Interpreter
  #--------------------------------------------------------------------------
  def event
    return $game_map.events[@event_id]
  end
end
