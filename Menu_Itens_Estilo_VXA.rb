#===========================================================================
# Item Estilo VXA
#---------------------------------------------------------------------------
# Autor: Rayner B.
#---------------------------------------------------------------------------
# O Script deixa a Cena de Itens mais parecida com a Cena de 
# Itens do RPG Maker VX Ace porém não foi possível adicionar a 
# Cena de Itens Chave... Por enquanto.
#---------------------------------------------------------------------------
# Basta apenas colar este Script Acima do Main para faze-lo
# funcionar.
#
# *Requisitos:
#             Dar os devidos créditos.
#
# Qualquer coisa, acesse:
#                        http://espacorpgmaker.umforum.net
#                        https://somniumsystem.blogspot.com
#=============================================================================

class TiposDeItens < Window_Selectable
  
  def initialize
    super(0, 64, 640, 64)
    @item_max = 3
    @column_max = 3
    @commands = ["Item", "Armadura", "Arma"]
    self.contents = Bitmap.new(width - 32, @item_max * 32)
    refresh
    self.index = 0
  end
  
  #--------------------------------------------------------------------------
  # Atualização
  #--------------------------------------------------------------------------
  
  def refresh
    self.contents.clear
    for i in 0...@item_max
      draw_item(i)
    end
  end
  
  #--------------------------------------------------------------------------
  # Desenhar Item
  #
  #     index : índice
  #--------------------------------------------------------------------------
  
  def draw_item(index)
    x = 3 + index * 250
    self.contents.draw_text(x, 0, 128, 32, @commands[index])
  end
  
end



class Janela_Itens < Window_Selectable
 
  #--------------------------------------------------------------------------
  # Inicialização dos Objetos
  #--------------------------------------------------------------------------
  
  def initialize
    super(0, 128, 640, 416)
    @column_max = 2
    refresh
    # Caso se está em uma batalha a janela será movida para o centro da tela
    # e esta é transformada em semi-transparente
    if $game_temp.in_battle
      self.y = 64
      self.height = 256
      self.back_opacity = 160
    end
  end
  
  #--------------------------------------------------------------------------
  # Selecionar Item
  #--------------------------------------------------------------------------
  
  def item
    return @data[self.index]
  end
  
  #--------------------------------------------------------------------------
  # Atualização
  #--------------------------------------------------------------------------
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    # Adicionar Item
    for i in 1...$data_items.size
      if $game_party.item_number(i) > 0
        @data.push($data_items[i])   #*Aviso
      end
    end
    # Caso haja algum Item aqui a janela é desenhada, junto com todos os Itens
    @item_max = @data.size
    if @item_max > 0
      self.contents = Bitmap.new(width - 32, row_max * 32)
      for i in 0...@item_max
        draw_item(i)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # Desenhar Item
  #
  #     index : índice de Itens
  #--------------------------------------------------------------------------
  
  def draw_item(index)
    item = @data[index]
    case item
    when RPG::Item
      number = $game_party.item_number(item.id)
    end
    if item.is_a?(RPG::Item) and
       $game_party.item_can_use?(item.id)
      self.contents.font.color = normal_color
    else
      self.contents.font.color = disabled_color
    end
    x = 4 + index % 2 * (288 + 32)
    y = index / 2 * 32
    rect = Rect.new(x, y, self.width / @column_max - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    opacity = self.contents.font.color == normal_color ? 255 : 128
    self.contents.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    self.contents.draw_text(x + 28, y, 212, 32, item.name, 0)
    self.contents.draw_text(x + 240, y, 16, 32, ":", 1)
    self.contents.draw_text(x + 256, y, 24, 32, number.to_s, 2)
  end
  
  #--------------------------------------------------------------------------
  # Atualização do Texto de Ajuda
  #--------------------------------------------------------------------------
  
  def update_help
    @help_window.set_text(self.item == nil ? "" : self.item.description)
  end
end



class Janela_Armadura < Window_Selectable
 
  #--------------------------------------------------------------------------
  # Inicialização dos Objetos
  #--------------------------------------------------------------------------
  
  def initialize
    super(0, 128, 640, 416)
    @column_max = 2
    refresh
    # Caso se está em uma batalha a janela será movida para o centro da tela
    # e esta é transformada em semi-transparente
    if $game_temp.in_battle
      self.y = 64
      self.height = 256
      self.back_opacity = 160
    end
  end
  
  #--------------------------------------------------------------------------
  # Selecionar Item
  #--------------------------------------------------------------------------
  
  def item
    return @data[self.index]
  end
  
  #--------------------------------------------------------------------------
  # Atualização
  #--------------------------------------------------------------------------
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    # Adicionar Item
    # Também é adicionados as Armaduras caso se esteja fora de 
    # uma batalha
    unless $game_temp.in_battle
      for i in 1...$data_armors.size
        if $game_party.armor_number(i) > 0
          @data.push($data_armors[i])
        end
      end
    end
    # Caso haja algum Item aqui a janela é desenhada, junto com todos os Itens
    @item_max = @data.size
    if @item_max > 0
      self.contents = Bitmap.new(width - 32, row_max * 32)
      for i in 0...@item_max
        draw_item(i)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # Desenhar Item
  #
  #     index : índice de Itens
  #--------------------------------------------------------------------------
  
  def draw_item(index)
    item = @data[index]
    case item
    when RPG::Armor
      number = $game_party.armor_number(item.id)
    end
    if item.is_a?(RPG::Item) and
       $game_party.item_can_use?(item.id)
      self.contents.font.color = normal_color
    else
      self.contents.font.color = disabled_color
    end
    x = 4 + index % 2 * (288 + 32)
    y = index / 2 * 32
    rect = Rect.new(x, y, self.width / @column_max - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    opacity = self.contents.font.color == normal_color ? 255 : 128
    self.contents.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    self.contents.draw_text(x + 28, y, 212, 32, item.name, 0)
    self.contents.draw_text(x + 240, y, 16, 32, ":", 1)
    self.contents.draw_text(x + 256, y, 24, 32, number.to_s, 2)
  end
  
  #--------------------------------------------------------------------------
  # Atualização do Texto de Ajuda
  #--------------------------------------------------------------------------
  
  def update_help
    @help_window.set_text(self.item == nil ? "" : self.item.description)
  end
end


class Janela_Arma < Window_Selectable
 
  #--------------------------------------------------------------------------
  # Inicialização dos Objetos
  #--------------------------------------------------------------------------
  
  def initialize
    super(0, 128, 640, 416)
    @column_max = 2
    refresh
    # Caso se está em uma batalha a janela será movida para o centro da tela
    # e esta é transformada em semi-transparente
    if $game_temp.in_battle
      self.y = 64
      self.height = 256
      self.back_opacity = 160
    end
  end
  
  #--------------------------------------------------------------------------
  # Selecionar Item
  #--------------------------------------------------------------------------
  
  def item
    return @data[self.index]
  end
  
  #--------------------------------------------------------------------------
  # Atualização
  #--------------------------------------------------------------------------
  
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    # Adicionar Item
    # Também é adicionados as Armas caso se esteja fora de uma
    # batalha
    unless $game_temp.in_battle
      for i in 1...$data_weapons.size
        if $game_party.weapon_number(i) > 0
          @data.push($data_weapons[i])
        end
      end
    end
    # Caso haja algum Item aqui a janela é desenhada, junto com todos os Itens
    @item_max = @data.size
    if @item_max > 0
      self.contents = Bitmap.new(width - 32, row_max * 32)
      for i in 0...@item_max
        draw_item(i)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # Desenhar Item
  #
  #     index : índice de Itens
  #--------------------------------------------------------------------------
  
  def draw_item(index)
    item = @data[index]
    case item
    when RPG::Weapon
      number = $game_party.weapon_number(item.id)
    end
    if item.is_a?(RPG::Item) and
       $game_party.item_can_use?(item.id)
      self.contents.font.color = normal_color
    else
      self.contents.font.color = disabled_color
    end
    x = 4 + index % 2 * (288 + 32)
    y = index / 2 * 32
    rect = Rect.new(x, y, self.width / @column_max - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    opacity = self.contents.font.color == normal_color ? 255 : 128
    self.contents.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    self.contents.draw_text(x + 28, y, 212, 32, item.name, 0)
    self.contents.draw_text(x + 240, y, 16, 32, ":", 1)
    self.contents.draw_text(x + 256, y, 24, 32, number.to_s, 2)
  end
  
  #--------------------------------------------------------------------------
  # Atualização do Texto de Ajuda
  #--------------------------------------------------------------------------
  
  def update_help
    @help_window.set_text(self.item == nil ? "" : self.item.description)
  end
end



class Scene_Item
  
  def main
    
    # Aqui é criado a janela de Ajuda
    @janela_de_ajuda = Window_Help.new
    # ... Itens
    @janela_itens = Janela_Itens.new
    # ... Armadura
    @janela_armadura = Janela_Armadura.new
    # ... Armas
    @janela_arma = Janela_Arma.new
    # ... Opções
    @opcoes = TiposDeItens.new
    # ... Alvo
    @janela_de_alvo = Window_Target.new
    
    # Agora será definido a Visibilidade das janelas.
    @janela_itens.visible = true
    @janela_armadura.visible = false
    @janela_arma.visible = false
    @janela_de_alvo.visible = false
    
    # Agora será definido se as Janelas estão ativas ou não.
    @janela_itens.active = false
    @janela_armadura.active = false
    @janela_arma.active = false
    @janela_de_alvo.active = false
    
    @janela_itens.help_window = @janela_de_ajuda
    @janela_armadura.help_window = @janela_de_ajuda
    @janela_arma.help_window = @janela_de_ajuda
    
    # Executar transição
    Graphics.transition
    # Loop principal
    loop do
      # Atualizar a tela de jogo
      Graphics.update
      # Atualizar a entrada de informações
      Input.update
      # Atualização do frame
      update
      # Abortar o loop se a tela foi alterada
      if $scene != self
        break
      end
    end
    # Prepara para transição
    Graphics.freeze
    # Exibição das janelas
    @janela_de_ajuda.dispose
    @opcoes.dispose
    @janela_itens.dispose
    @janela_armadura.dispose
    @janela_arma.dispose
  end
  
  #--------------------------------------------------------------------------
  # Atualização do Frame
  #--------------------------------------------------------------------------
  
  def update
    # Atualização das Janelas
    @janela_de_ajuda.update
    @janela_itens.update
    @janela_armadura.update
    @janela_arma.update
    @opcoes.update
    
    case @opcoes.index
      when 0 # Item
        @janela_armadura.visible = false
        @janela_itens.visible = true
      when 1 # Armadura
        @janela_itens.visible = false
        @janela_arma.visible = false
        @janela_armadura.visible = true
      when 2 # Arma
        @janela_armadura.visible = false
        @janela_arma.visible = true
      end
      
    if @opcoes.active
      update_command
      return
    end
    
    @janela_de_alvo.update
    
    if @janela_itens.active
      update_item
      return
    end
    
    if @janela_armadura.active
      update_item
      return
    end
    
    if @janela_arma.active
      update_item
      return
    end
    
    if @janela_de_alvo.active
      update_target
      return
    end
    
  end
  
  
  
  def update_command
    # Se o botão B for pressionado
    if Input.trigger?(Input::B)
      # Reproduzir SE de cancelamento
      $game_system.se_play($data_system.cancel_se)
      # Alternar para a tela do Mapa
      $scene = Scene_Menu.new(0)
      return
    end
    
    # Se o botão C for pressionado
    if Input.trigger?(Input::C)
      # Ramificação por posição na janela de comandos
      case @opcoes.index
      when 0  # Item
        @opcoes.active = false
        @janela_itens.active = true
        @janela_itens.visible = true
        @janela_itens.index = 0
      when 1  # Armadura
        @opcoes.active = false
        @janela_armadura.active = true
        @janela_armadura.visible = true
        @janela_armadura.index = 0
      when 2  # Arma (Weapon)
        @opcoes.active = false
        @janela_arma.active = true
        @janela_arma.visible = true
        @janela_arma.index = 0
      end
      return
    end
  end
  
  
  #--------------------------------------------------------------------------
  # Atualização do Frame (Quando a janela de Itens estiver Ativa)
  #--------------------------------------------------------------------------
  
  def update_item
    # Se o botão B for pressionado
    if Input.trigger?(Input::B)
      if @janela_itens.active
        @janela_itens.active = false
        @janela_itens.index = -1
        @opcoes.active = true
        @opcoes.index = 0
        return
      elsif @janela_armadura.active
        @janela_armadura.active = false
        @janela_armadura.index = -1
        @opcoes.active = true
        @opcoes.index = 1
        return
      elsif @janela_arma.active
        @janela_arma.active = false
        @janela_arma.index = -1
        @opcoes.active = true
        @opcoes.index = 2
        return
      end
      # Reproduzir SE de cancelamento
      $game_system.se_play($data_system.cancel_se)
      # Alternar para a tela de Menu
      $scene = Scene_Menu.new(0)
      return
    end
    # Se o botão C for pressionado
    if Input.trigger?(Input::C)
      
      if @janela_itens.visible
        # Selecionar os dados escolhidos na janela de Itens
        @item = @janela_itens.item
        # Se não for um Item usável
        unless @item.is_a?(RPG::Item)
          # Reproduzir SE de erro
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Se não puder ser usado
        unless $game_party.item_can_use?(@item.id)
          # Reproduzir SE de erro
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Reproduzir SE de OK
        $game_system.se_play($data_system.decision_se)
        # Se o alcance do Item for um aliado
        if @item.scope >= 3
          # Ativar a janela alvo
          @janela_itens.active = false
          @janela_de_alvo.x = (@janela_itens.index + 1) % 2 * 304
          @janela_de_alvo.visible = true
          @janela_de_alvo.active = true
          # Definir a posição do cursor no alvo (aliado / todo grupo)
          if @item.scope == 4 || @item.scope == 6
            @janela_de_alvo.index = -1
          else
            @janela_de_alvo.index = 0
          end
        # Se o alcance for outro senão um aliado
        else
          # Se o ID do evento comum for inválido
          if @item.common_event_id > 0
            # Chamar evento comum da reserva
            $game_temp.common_event_id = @item.common_event_id
            # Reproduzir SE do Item
            $game_system.se_play(@item.menu_se)
            # Se for consumível
            if @item.consumable
              # Diminui 1 Item da quantidade total
              $game_party.lose_item(@item.id, 1)
              # Desenhar o Item
              @janela_itens.draw_item(@janela_itens.index)
            end
            # Alternar para a tela do Mapa
            $scene = Scene_Map.new
            return
          end
        end
      elsif @janela_armadura.visible
        # Selecionar os dados escolhidos na janela de Itens
        @item = @janela_armadura.item
        # Se não for um Item usável
        unless @item.is_a?(RPG::Item)
          # Reproduzir SE de erro
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Se não puder ser usado
        unless $game_party.item_can_use?(@item.id)
          # Reproduzir SE de erro
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Reproduzir SE de OK
        $game_system.se_play($data_system.decision_se)
        # Se o alcance do Item for um aliado
        if @item.scope >= 3
          # Ativar a janela alvo
          @janela_armadura.active = false
          @janela_de_alvo.x = (@janela_armadura.index + 1) % 2 * 304
          @janela_de_alvo.visible = true
          @janela_de_alvo.active = true
          # Definir a posição do cursor no alvo (aliado / todo grupo)
          if @item.scope == 4 || @item.scope == 6
            @janela_de_alvo.index = -1
          else
            @janela_de_alvo.index = 0
          end
        # Se o alcance for outro senão um aliado
        else
          # Se o ID do evento comum for inválido
          if @item.common_event_id > 0
            # Chamar evento comum da reserva
            $game_temp.common_event_id = @item.common_event_id
            # Reproduzir SE do Item
            $game_system.se_play(@item.menu_se)
            # Se for consumível
            if @item.consumable
              # Diminui 1 Item da quantidade total
              $game_party.lose_item(@item.id, 1)
              # Desenhar o Item
              @janela_armadura.draw_item(@janela_armadura.index)
            end
            # Alternar para a tela do Mapa
            $scene = Scene_Map.new
            return
          end
        end
      elsif @janela_arma.visible
        # Selecionar os dados escolhidos na janela de Itens
        @item = @janela_arma.item
        # Se não for um Item usável
        unless @item.is_a?(RPG::Item)
          # Reproduzir SE de erro
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Se não puder ser usado
        unless $game_party.item_can_use?(@item.id)
          # Reproduzir SE de erro
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Reproduzir SE de OK
        $game_system.se_play($data_system.decision_se)
        # Se o alcance do Item for um aliado
        if @item.scope >= 3
          # Ativar a janela alvo
          @janela_arma.active = false
          @janela_de_alvo.x = (@janela_arma.index + 1) % 2 * 304
          @janela_de_alvo.visible = true
          @janela_de_alvo.active = true
          # Definir a posição do cursor no alvo (aliado / todo grupo)
          if @item.scope == 4 || @item.scope == 6
            @janela_de_alvo.index = -1
          else
            @janela_de_alvo.index = 0
          end
        # Se o alcance for outro senão um aliado
        else
          # Se o ID do evento comum for inválido
          if @item.common_event_id > 0
            # Chamar evento comum da reserva
            $game_temp.common_event_id = @item.common_event_id
            # Reproduzir SE do Item
            $game_system.se_play(@item.menu_se)
            # Se for consumível
            if @item.consumable
              # Diminui 1 Item da quantidade total
              $game_party.lose_item(@item.id, 1)
              # Desenhar o Item
              @janela_arma.draw_item(@janela_arma.index)
            end
            # Alternar para a tela do Mapa
            $scene = Scene_Map.new
            return
          end
        end
      end
      
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # Atualização do Frame (Quando a janela alvo estiver Ativa)
  #--------------------------------------------------------------------------
  
  def update_target
    # Se o botão B for pressionado
    if Input.trigger?(Input::B)
      # Reproduzir SE de cancelamento
      $game_system.se_play($data_system.cancel_se)
      # Se for impossível utilizar porque o Item não existe mais
      unless $game_party.item_can_use?(@item.id)
        # Recriar os conteúdos da janela de ìtens
        @janela_itens.refresh
        @janela_armadura.refresh
        @janela_arma.refresh
      end
      # Apagar a janela alvo
      @janela_itens.active = true
      @janela_de_alvo.visible = false
      @janela_de_alvo.active = false
      return
    end
    # Se o botão C for pressionado
    if Input.trigger?(Input::C)
      # Se chegar ao número 0 da quantidade de Itens
      if $game_party.item_number(@item.id) == 0
        # Reproduzir SE de erro
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Se o alvo for todos o Grupo
      if @janela_de_alvo.index == -1
        # Os efeitos serão aplicados a todos
        usado = false
        for i in $game_party.actors
          usado |= i.item_effect(@item)
        end
      end
      # Se for apenas um aliado o alvo
      if @janela_de_alvo.index >= 0
        # Aplicar os efeitos apenas no Herói alvo
        alvo = $game_party.actors[@janela_de_alvo.index]
        usado = alvo.item_effect(@item)
      end
      # Se o Item for usado
      if usado
        # Reproduzir SE do Item
        $game_system.se_play(@item.menu_se)
        # Se for consumível
        if @item.consumable
          # Diminui 1 item da quantidade total
          $game_party.lose_item(@item.id, 1)
          # Redesenhar o Item
          @janela_itens.draw_item(@janela_itens.index)
        end
        # Recriar os conteúdos da janela alvo
        @janela_de_alvo.refresh
        # Se todos no Grupo de Heróis estiverm mortos
        if $game_party.all_dead?
          # Alternar para a tela de Game Over
          $scene = Scene_Gameover.new
          return
        end
        # Se o ID do evento comum for válido
        if @item.common_event_id > 0
          # Chamar o evento comum da reserva
          $game_temp.common_event_id = @item.common_event_id
          # Alternar para a tela do Mapa
          $scene = Scene_Map.new
          return
        end
      end
      # Se o Item não for usado
      unless usado
        # Reproduzir SE de erro
        $game_system.se_play($data_system.buzzer_se)
      end
      return
    end
  end
  
end

#===========================================================================
#                      Somnium System
#===========================================================================