library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity PWM_generator is
  -- define the clock freq and pulse-width modeulation frequency
  generic (
    clk_freq_hz : positive := 50_000_000;
    pwm_freq_hz : positive := 20_000
  );
  -- declare ports for the PWM generator
  port (
    clk : in std_logic;
    reset: in std_logic;
    enable: in std_logic;
    -- duty cycle is passed as an unsigned value in the range 0-100
    duty_cycle_i : unsigned(6 downto 0);
    pwm_o : out std_logic
  );
end entity;

architecture rtl of PWM_generator is
-- calculate the number of cycles to generate PWM frequency
constant clock_ticks: integer := clk_freq_hz / pwm_freq_hz;

-- declare a signal to hold the duty cycle value
signal duty_cycle_trig: unsigned(6 downto 0) := (others => '0');

-- declare counter for PWM generation
-- natural allows for only positive values
-- the range is set to the number of clock ticks 
signal counter: natural range 0 to clock_ticks - 1 := 0;

-- number of HIGH clock cycles in PWM period
signal duty_ticks: natural range 0 to clock_ticks := 0;


begin
  -- calculate the number of clock ticks for the given duty cycle
  -- converts the duty cycle value in range 0-100 to the number of clock ticks for the given PWM frequency
  duty_ticks <= clock_ticks 
    when duty_cycle_trig >= 100 
    else (to_integer(duty_cycle_trig) * clock_ticks) / 100;
  
  -- generates the output signal based on the duty cycle and counter value
  -- if else are sequential statements hence cant be used outside process
  -- uses when else statement for complex boolean expresions 
  pwm_o <= '1' when (enable = '1' and counter < duty_ticks) else '0';

  process(clk, reset)
  begin
    -- asynchronous reset
    if reset = '1' then
      counter <= 0;
      duty_cycle_trig <= (others => '0');

    elsif rising_edge(clk) then
      -- reset counter if enable is low
      if enable = '0' then
        counter <= 0;
        duty_cycle_trig <= duty_cycle_i;
      else
        -- counter increment 
        if counter < clock_ticks - 1 then
          counter <= counter + 1;
        else 
          counter <= 0;
          -- lock duty_cycle_value to duty_cycle_trig to avoid glitches in the output
          duty_cycle_trig <= duty_cycle_i;
        end if;
      end if;
    end if;
  end process;

end architecture;
