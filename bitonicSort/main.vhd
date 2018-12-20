library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.all;



entity main is
	port (
		clk: in STD_LOGIC;
		rst_n: in STD_LOGIC;
		tx: out STD_LOGIC;
		rx: in  STD_LOGIC;
		led: out unsigned(7 downto 0)
	);
end main;

architecture Flow of main is


	constant size: integer := 3;

	component bitonicSort is
		generic(
			logN: integer := 3
		);
		port (
			unsorted: in list(2**logN - 1 downto 0);
			sorted:  out list(2**logN - 1 downto 0)
		);
	end component;
	
	
	component UART_RX is
		generic (
			g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
		);
		port (
			i_Clk       : in  std_logic;
			i_RX_Serial : in  std_logic;
			o_RX_DV     : out std_logic;
			o_RX_Byte   : out std_logic_vector(7 downto 0)
		);
	end component;
	
	component UART_TX is
		generic (
			g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
		);
		port (
			i_Clk       : in  std_logic;
			i_TX_DV     : in  std_logic;
			i_TX_Byte   : in  std_logic_vector(7 downto 0);
			o_TX_Active : out std_logic;
			o_TX_Serial : out std_logic;
			o_TX_Done   : out std_logic
		);
	end component;
	
	signal rst: std_logic;
	signal output: list(2 ** size - 1 downto 0);
	signal input: list(2 ** size downto 0);
	signal count: integer := 0;
	signal r_ready, t_ready, t_done, t_active, send : std_logic := '0';
	signal byteOut: unsigned(7 downto 0);
begin
	
	rst <= not rst_n;
	
	led(5 downto 0) <= to_unsigned(count, 6);
	led(7) <= send;
	led(6) <= t_active;
	
	sort: bitonicSort generic map(logN => size)
							   port map(unsorted => input(2 ** size downto 1), sorted => output);
	
	
	receiver: UART_RX generic map (g_CLKS_PER_BIT => 5208)
								port map (i_Clk => clk, i_RX_Serial => rx, o_RX_DV => r_ready, unsigned(o_RX_Byte) => input(0));
	
	
	transmitter: UART_TX generic map (g_CLKS_PER_BIT => 5208)
									port map (i_Clk => clk, i_TX_DV => t_ready, i_TX_Byte => std_logic_vector(byteOut), o_TX_Active => t_active, o_TX_Serial => tx, o_TX_Done => t_done);
	
	
	
	byteOut <= output(count mod (2 ** size));
	
	
	sendStatus: process(send, t_active)
	begin
		if t_active = '1' then
			t_ready <= '0';
		elsif send = '1' then
			t_ready <= '1';
		end if;
	end process sendStatus;
	
	
	counter: process(r_ready, count, rst)
	begin
		if (rst = '1') then
			count <= 0;
			send <= '0';
		elsif (r_ready'EVENT and r_ready = '1') then
			count <= (count + 1) mod (2**(size + 1));
			if count >= (2 ** size)-1 then
				send <= '1';
			else
				send <= '0';
			end if;
		end if;
	end process counter;
		
	inputShift: for I in 1 to 2 ** size generate
		process(r_ready)
		begin
			if (r_ready'EVENT and r_ready = '1') then
				if count < (2 ** size) then
					input(I) <= input(I-1);
				end if;
			end if;
		end process;
	end generate inputShift;
	
	
	
	
	
	

end Flow;

