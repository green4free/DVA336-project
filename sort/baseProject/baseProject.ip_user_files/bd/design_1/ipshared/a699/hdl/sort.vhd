




------------------------------------------------------------
-- Basic building block of sorter
--
-- takes two numbers and returns in a specified way
-- the smalles and the greatest of them on different
-- outputs.
------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity minMax is
		Generic (
			dir: boolean
		);
		Port (
			A: in unsigned(7 downto 0);
			B: in unsigned(7 downto 0);
			nA: out unsigned(7 downto 0);
			nB: out unsigned(7 downto 0)
		);
end minMax;

architecture Behavioral of minMax is
signal comp : boolean;
begin
	max:if dir generate
		comp <= A > B;
	end generate max;
	min:if not dir generate
		comp <= B > A;
	end generate min;


	nA <=
		A when comp else
		B;
	nB <= 
		B when comp else
        A;

end Behavioral;





------------------------------------------------------------
-- Actual sorting component
--
-- Sorts usning a bitonic sorting network.
------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.types.all;


entity bitonicSort is
	generic(
		logN: integer := 3
	);
	
	port (
		unsorted: in list(2**logN - 1 downto 0);
		sorted:  out list(2**logN - 1 downto 0)
	);
end bitonicSort;

architecture Behavioral of bitonicSort is
	component minMax is
		Generic (
			dir: boolean
		);
		Port (
			A: in unsigned(7 downto 0);
			B: in unsigned(7 downto 0);
			nA: out unsigned(7 downto 0);
			nB: out unsigned(7 downto 0)
		);
	end component;

	constant depth : integer := (logN * (logN + 1) / 2);

	type matrix is array(depth downto 0) of list(2**logN - 1 downto 0);

	signal network: matrix;


begin
	
	network(0) <= unsorted;
	sorted <= network(depth);
	
	
	l1: for i in 0 to logN - 1 generate
		l2: for j in 0 to i generate
		
			blueGreenBlock: for b in 0 to (2**(logN - i - 1)) - 1 generate
				--Start of bg block b * (2 ** (i + 1) )
				redBlock:for m in 0 to (2**j) - 1 generate 
					--Start of r block b * (2 ** (i + 1) ) + m * (2 ** (i - j + 1) )
					arrow:for n in 0 to 2**(i - j) - 1 generate
						--Sart of arrow b * (2 ** (i + 1) ) + m * (2 ** (i - j + 1) + n
						--Length of arrow 2 ** (i - j)
						swap: minMax generic map(dir => (b mod 2 /= 0) )
						                port map(
							             A => network((i * (i+1)) / 2 + j) (b * (2 ** (i + 1)) + m * (2 ** (i - j + 1)) + n ),
							             B => network((i * (i+1)) / 2 + j) ((b * (2 ** (i + 1) ) + m * (2 ** (i - j + 1)) + n) + 2**(i-j)),
							             nA => network((i * (i+1)) / 2 + j + 1) (b * (2 ** (i + 1) ) + m * (2 ** (i - j + 1)) + n ),
							             nB => network((i * (i+1)) / 2 + j + 1) ((b * (2 ** (i + 1) ) + m * (2 ** (i - j + 1)) + n) + 2**(i-j))
						);
						
					end generate arrow;
				end generate redBlock;
				
			end generate blueGreenBlock;
			
		end generate l2;
	end generate l1;
	
				


end Behavioral;


