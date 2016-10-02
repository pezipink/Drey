import du;
import types;
import pandemic;
mixin(DU!q{

    Union GameStates =
      | MainMenu
      | InPlay of state : Pandemic

    Union ControlMessages =
      | Status of message : string

      });
