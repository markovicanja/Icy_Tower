--------------------------------------------------------------------------------
--
--   FileName:         ps2_transceiver.vhd
--   Dependencies:     debounce.vhd
--   Design Software:  Quartus II 64-bit Version 13.1.0 Build 162 SJ Web Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 1/19/2018 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ps2_transceiver2 IS
	GENERIC(
		clk_freq						:	INTEGER := 50_000_000;	--system clock frequency in Hz
		debounce_counter_size	:	INTEGER := 8);				--set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
	PORT(
		clk				:	IN			STD_LOGIC;								--system clock
		tx_ena			:	IN			STD_LOGIC;								--enable transmit
		tx_cmd			:	IN			STD_LOGIC_VECTOR(8 DOWNTO 0);		--8-bit command to transmit, MSB is parity bit
		tx_busy			:	OUT		STD_LOGIC;								--indicates transmit in progress
		ps2_code			:	OUT		STD_LOGIC_VECTOR(7 DOWNTO 0);		--code received from PS/2
		ps2_code_new	:	OUT		STD_LOGIC;								--flag that new PS/2 code is available on ps2_code bus
		ps2_clk			:	INOUT		STD_LOGIC;								--PS/2 port clock signal
		ps2_data			:	INOUT		STD_LOGIC);								--PS/2 port data signal
END ps2_transceiver2;

ARCHITECTURE logic OF ps2_transceiver2 IS
	TYPE machine IS(receive, inhibit, transact, tx_complete);				--needed states
	SIGNAL state 				:	machine := receive;								--state machine
	SIGNAL sync_ffs			:	STD_LOGIC_VECTOR(1 DOWNTO 0);					--synchronizer flip-flops for PS/2 signals
	SIGNAL ps2_clk_int		:	STD_LOGIC;											--debounced input clock signal from PS/2 port
	SIGNAL ps2_clk_int_prev	:	STD_LOGIC;											--previous state of the ps2_clk_int signal
	SIGNAL ps2_data_int		:	STD_LOGIC;											--debounced input data signal from PS/2 port
	SIGNAL ps2_word			:	STD_LOGIC_VECTOR(10 DOWNTO 0);				--stores the ps2 data word (both tx and rx)
	SIGNAL timer		 		:	INTEGER RANGE 0 TO clk_freq/10_000 := 0;	--counter to determine both inhibit period and when PS/2 is idle
	SIGNAL bit_cnt				:	INTEGER RANGE 0 TO 11 := 0;					--count the number of clock pulses during transmit
	
	--declare debounce component for debouncing PS2 input signals
	COMPONENT debounce IS
		GENERIC(
			counter_size  :  INTEGER);	--debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
		PORT(
			clk     : IN  STD_LOGIC;	--input clock
			button  : IN  STD_LOGIC;	--input signal to be debounced
			result  : OUT STD_LOGIC);	--debounced signal
	END COMPONENT;
BEGIN

	--synchronizer flip-flops
	PROCESS(clk)
	BEGIN
		IF(clk'EVENT AND clk = '1') THEN		--rising edge of system clock
			sync_ffs(0) <= ps2_clk;					--synchronize PS/2 clock signal
			sync_ffs(1) <= ps2_data;				--synchronize PS/2 data signal
		END IF;
	END PROCESS;

	--debounce PS2 input signals
	debounce_ps2_clk: debounce
		GENERIC MAP(counter_size => debounce_counter_size)
		PORT MAP(clk => clk, button => sync_ffs(0), result => ps2_clk_int);
	debounce_ps2_data: debounce
		GENERIC MAP(counter_size => debounce_counter_size)
		PORT MAP(clk => clk, button => sync_ffs(1), result => ps2_data_int);

	--state machine to control transmit and receive processes
	PROCESS(clk)
	BEGIN
		IF(clk'EVENT AND clk = '1') THEN								--rising edge of system clock
			ps2_clk_int_prev <= ps2_clk_int;									--store previous value of the PS/2 clock signal
			CASE state IS															--implement state machine
			
				WHEN receive =>
					IF(tx_ena = '1') THEN											--transmit requested
					--receive*tx_ena=uslov1
						tx_busy <= '1';													--indicate transmit in progress
						timer <= 0;															--reset timer for inhibit timing
						--ne upisuje nista u 11-ti bit (najvisi)
						ps2_word(9 DOWNTO 0) <= tx_cmd & '0';						--load parity, command, and start bit into PS/2 data buffer
						bit_cnt <= 0;														--clear bit counter						
						state <= inhibit;													--inhibit communication to begin transaction
					ELSE																	--transmit not requested
					--uslov2=receive*not(tx_ena)
						tx_busy <= '0';													--indicate no transmit in progress
						ps2_clk <= 'Z';													--release PS/2 clock port
						ps2_data <= 'Z';													--release PS/2 data port		
						--clock in receive data
						IF(ps2_clk_int_prev = '1' AND ps2_clk_int = '0') THEN	--falling edge of PS2 clock
						--uslov3=uslov2*ps2_clk_fall
							ps2_word <= ps2_data_int & ps2_word(10 DOWNTO 1);		--shift contents of PS/2 data buffer
						END IF;	
						--determine if PS/2 port is idle
						IF(ps2_clk_int = '0') THEN										--low PS2 clock, PS/2 is active
						--uslov4=uslov2*not(ps2_clk_int)
							timer <= 0;							 								--reset idle counter
						ELSIF(timer < clk_freq/18_000) THEN							--PS2 clock has been high less than a half clock period (<55us)
						--uslov5
							timer <= timer + 1;   											--continue counting
						END IF;
						--output received data and port status					
						IF(timer = clk_freq/18_000) THEN								--idle threshold reached
						--uslov6
							ps2_code_new <= '1';												--set flag that new PS/2 code is available
							ps2_code <= ps2_word(8 DOWNTO 1);							--output new PS/2 code
						ELSE																	--PS/2 port active
						--uslov7
							ps2_code_new <= '0';												--set flag that PS/2 transaction is in progress
						END IF;
						state <= receive;													--continue streaming receive transactions
					END IF;
				
				WHEN inhibit =>
					IF(timer < clk_freq/10_000) THEN								--first 100us not complete
					--uslov8
						timer <= timer + 1;												--increment timer
						ps2_data <= 'Z';													--release data port
						ps2_clk <= '0';													--inhibit communication
						state <= inhibit;													--continue inhibit
					ELSE																	--100us complete
					--uslov9
						--da li treba u tom trenutku da se pusti ps_word(0) ili u sledecem taktu
						ps2_data <= ps2_word(0);										--output start bit to PS/2 data port
						state <= transact;												--proceed to send bits
					END IF;
					
				WHEN transact =>
					ps2_clk <= 'Z';													--release clock port
					IF(ps2_clk_int_prev = '1' AND ps2_clk_int = '0') THEN	--falling edge of PS2 clock
					--uslov10
						ps2_word <= ps2_data_int & ps2_word(10 DOWNTO 1);		--shift contents of PS/2 data buffer
						bit_cnt <= bit_cnt + 1;											--count clock falling edges
					END IF;
					IF(bit_cnt < 10) THEN											--all bits not sent
					--uslov11
						ps2_data <= ps2_word(0);										--connect serial output of PS/2 data buffer to data port
					ELSE																	--all bits sent
						ps2_data <= 'Z';													--release data port
					END IF;
					IF(bit_cnt = 11) THEN											--acknowledge bit received
					--uslov12
						state <= tx_complete;											--proceed to wait until the slave releases the bus
					ELSE																	--acknowledge bit not received
						state <= transact;												--continue transaction
					END IF;
				
				WHEN tx_complete =>
					IF(ps2_clk_int = '1' AND ps2_data_int = '1') THEN		--device has released the bus
					--uslov13
						state <= receive;													--proceed to receive data state
					ELSE																	--bus not released by device
						state <= tx_complete;											--wait for device to release bus										
					END IF;
			
			END CASE;
		END IF;
	END PROCESS;
	
END logic;