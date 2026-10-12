
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_PWM_generator is
end entity tb_PWM_generator;

architecture sim of tb_PWM_generator is

    -- Use a short PWM period to speed up simulation.
    constant CLK_FREQ_HZ : positive := 1000;
    constant PWM_FREQ_HZ : positive := 100;
    constant PERIOD_TICKS : positive :=
        CLK_FREQ_HZ / PWM_FREQ_HZ;

    constant CLK_PERIOD : time := 10 ns;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal enable        : std_logic := '0';
    signal duty_cycle_i  : unsigned(6 downto 0) := (others => '0');
    signal pwm_o         : std_logic;

begin

    -- Instantiate the device under test (DUT).
    dut : entity work.PWM_generator
        generic map (
            clk_freq_hz => CLK_FREQ_HZ,
            pwm_freq_hz => PWM_FREQ_HZ
        )
        port map (
            clk           => clk,
            reset         => reset,
            enable        => enable,
            duty_cycle_i  => duty_cycle_i,
            pwm_o         => pwm_o
        );

    -- Generate the FPGA clock.
    clock_generation : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Apply stimulus and check the output.
    stimulus : process

        -- Check one complete PWM period.
        -- The expected duty value is in percent.
        procedure check_period(
            constant duty_percent : in natural
        ) is
            variable high_ticks : natural;
            variable expected   : std_logic;
        begin
            if duty_percent >= 100 then
                high_ticks := PERIOD_TICKS;
            else
                high_ticks :=
                    (duty_percent * PERIOD_TICKS) / 100;
            end if;

            -- Check each counter state from 0 to PERIOD_TICKS-1.
            for tick in 0 to PERIOD_TICKS - 1 loop

                if tick < high_ticks then
                    expected := '1';
                else
                    expected := '0';
                end if;

                wait for 1 ns;

                assert pwm_o = expected
                    report
                        "PWM mismatch: duty=" &
                        integer'image(duty_percent) &
                        "%, tick=" & integer'image(tick) &
                        ", expected=" & std_logic'image(expected) &
                        ", got=" & std_logic'image(pwm_o)
                    severity error;

                -- Advance to the next counter state.
                wait until rising_edge(clk);
            end loop;

            report
                "PASS: " & integer'image(duty_percent) &
                "% duty cycle"
                severity note;
        end procedure;

    begin

        -- TEST 1: Reset.
        reset <= '1';
        enable <= '0';
        duty_cycle_i <= to_unsigned(0, duty_cycle_i'length);

        wait for 2 * CLK_PERIOD;
        wait for 1 ns;

        assert pwm_o = '0'
            report "FAIL: PWM output should be LOW during reset"
            severity error;

        reset <= '0';

        -- Allow the DUT to sample its inputs while disabled.
        wait until rising_edge(clk);
        wait for 1 ns;

        report "Starting PWM tests" severity note;

        -- TEST 2: 0% duty cycle.
        duty_cycle_i <= to_unsigned(0, duty_cycle_i'length);
        enable <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        enable <= '1';
        check_period(0);

        -- TEST 3: 25% duty cycle.
        enable <= '0';
        duty_cycle_i <= to_unsigned(25, duty_cycle_i'length);
        wait until rising_edge(clk);
        wait for 1 ns;
        enable <= '1';
        check_period(25);

        -- TEST 4: 50% duty cycle.
        enable <= '0';
        duty_cycle_i <= to_unsigned(50, duty_cycle_i'length);
        wait until rising_edge(clk);
        wait for 1 ns;
        enable <= '1';
        check_period(50);

        -- TEST 5: 100% duty cycle.
        enable <= '0';
        duty_cycle_i <= to_unsigned(100, duty_cycle_i'length);
        wait until rising_edge(clk);
        wait for 1 ns;
        enable <= '1';
        check_period(100);

        -- TEST 6: Values above 100% saturate to 100%.
        enable <= '0';
        duty_cycle_i <= to_unsigned(110, duty_cycle_i'length);
        wait until rising_edge(clk);
        wait for 1 ns;
        enable <= '1';
        check_period(110);

        -- TEST 7: Disable while running.
        wait until rising_edge(clk);
        enable <= '0';
        wait for 1 ns;

        assert pwm_o = '0'
            report "FAIL: PWM output should be LOW when disabled"
            severity error;

        report "PASS: disable behavior" severity note;

        -- TEST 8: Change duty cycle during a period.
        -- First load 25% while disabled.
        duty_cycle_i <= to_unsigned(25, duty_cycle_i'length);
        wait until rising_edge(clk);
        wait for 1 ns;
        enable <= '1';

        -- Check the beginning of the 25% period.
        wait for 1 ns;
        assert pwm_o = '1'
            report "FAIL: 25% period should start HIGH"
            severity error;

        -- Change input halfway through the period.
        for i in 1 to PERIOD_TICKS / 2 loop
            wait until rising_edge(clk);
        end loop;

        duty_cycle_i <= to_unsigned(75, duty_cycle_i'length);

        -- The active period must still use 25%.
        -- Finish checking the remaining ticks.
        for tick in PERIOD_TICKS / 2 to PERIOD_TICKS - 1 loop
            wait for 1 ns;

            if tick < (25 * PERIOD_TICKS) / 100 then
                assert pwm_o = '1'
                    report "FAIL: current period changed unexpectedly"
                    severity error;
            else
                assert pwm_o = '0'
                    report "FAIL: current period changed unexpectedly"
                    severity error;
            end if;

            wait until rising_edge(clk);
        end loop;

        -- The new 75% command is latched at the period boundary.
        check_period(75);

        report "PASS: duty-cycle update at period boundary"
            severity note;

        report "All PWM tests completed." severity note;

        wait;
    end process;

end architecture sim;
