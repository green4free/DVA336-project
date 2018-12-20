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
	signal countIn: unsigned(size downto 0);
	signal countOut: unsigned(20 downto 0) := (others => '0');
	signal r_ready, t_ready, t_done, t_active: std_logic := '0';
	signal byteOut: unsigned(7 downto 0);
	
	type state is (R, W);
	signal mode: state := R;
begin
	
	rst <= not rst_n;
	
	led(size downto 0) <= countIn;
	led(6 downto size + 1) <= (others => '0');
	led(7) <= t_active;
	
	sort: bitonicSort generic map(logN => size)
							   port map(unsorted => input(2 ** size downto 1), sorted => output);
	
	
	receiver: UART_RX generic map (g_CLKS_PER_BIT => 5208)
								port map (i_Clk => clk, i_RX_Serial => rx, o_RX_DV => r_ready, unsigned(o_RX_Byte) => input(0));
	
	
	transmitter: UART_TX generic map (g_CLKS_PER_BIT => 5208)
									port map (i_Clk => clk, i_TX_DV => t_ready, i_TX_Byte => std_logic_vector(byteOut), o_TX_Active => t_active, o_TX_Serial => tx, o_TX_Done => t_done);
	
	

	byteOut <= output(to_integer(countOut(20 downto 20 - size)));
	
	t_ready <= countOut(20 - size - 1);
	
	counter: process(r_ready, clk, rst, mode, countIn, countOut)
	begin
		if (rst = '1') then
			countIn <= (others => '0');
			countOut <= (others => '0');
			mode <= R;
		else 
			case mode is
				when R =>
				if (r_ready'EVENT and r_ready = '1') then
					countIn <= countIn + 1;
				end if;
				if countIn = to_unsigned(2**size- 1, size) then
					mode <= W;
					countIn <= (others => '0');
				end if;
				
				when W =>
				if clk'EVENT and clk = '1' then
					if t_active = '0' then
						countOut <= countOut + 1;
					end if;
					if countOut(20 downto 20 - size) = to_unsigned(2**size- 1, size) then
						mode <= R;
						countOut <= (others => '0');
					end if;
				end if;
			end case;
		end if;
	end process counter;
	
		
		
	inputShift: for I in 1 to 2 ** size generate
		process(r_ready)
		begin
			if (r_ready'EVENT and r_ready = '1') then
				input(I) <= input(I-1);
			end if;
		end process;
	end generate inputShift;
	
	
	
	
	
	

end Flow;

