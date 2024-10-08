----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/08/2024 03:07:52 PM
-- Design Name: 
-- Module Name: phy_com - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity phy_com is
port(RXCLK, RXCTL, RXD0, RXD1, RXD2, RXD3 : in std_logic;
	DXCLK, DXCTL, DXD0, DXD1, DXD2, DXD3 : out std_logic;
	MDIO : inout std_logic; -- management io pin
	MDC : out std_logic;	-- management interface clk
	clk125 : in std_logic);

end phy_com;

architecture behav of phy_com is
	signal ram : std_logic_vector(1023 downto 0);
	signal addr : integer range 0 to 1023 := 0;
	signal sof : integer range 0 to 1023;
    
begin
	process(RXCLK)
	begin
    	if(rising_edge(RXCLK)) then
        	-- read rd, should also check rxctl for data valid
        	ram(addr) <= RXD0;
        	ram(addr+1) <= RXD1;
        	ram(addr+2) <= RXD2;
        	ram(addr+3) <= RXD3;
        	addr <= addr+4;
    	end if;

    	if (falling_edge(RXCLK)) then
        	-- read rd
        	ram(addr) <= RXD0;
        	ram(addr+1) <= RXD1;
        	ram(addr+2) <= RXD2;
        	ram(addr+3) <= RXD3;
        	addr <= addr+4;
    	end if;
	end process;

	process(addr) -- this assumes data is being recieved in correct nibble frame
              	-- could replicate logic for 4 bit offsets to potentially account
              	-- data recieving should be treated somewhat separate from decoding
	variable scanbuf : std_logic_vector(63 downto 0);
	variable low_addr : integer range 0 to 1023;
	begin
    	low_addr := addr - 63;
    	scanbuf := ram(addr downto low_addr); -- reversing bit order for last bit recieved as LSB
    	if (scanbuf = x"55555555555555AB") then -- 7 bytes 01010101 and 1 of 10101011 (FSD) -> probably wrong hex
        	-- start of frame recieved
        	sof <= low_addr;
        	-- next 6 bytes are dest MAC
        	-- next 6 bytes are sender MAC
        	-- next 2 bytes are type/len
        	-- then for len bytes, data is sent
        	-- then last byte is FCS  
    	end if;
	end process;
    
	process(sof)
	begin
    	-- when new frame established, must immediately start calculating FCS CRC
    	-- if we are truly invisible, no need to determine if packets are valid
	-- buffer scan logic
	end process;
    
	-- dest mac = sof + 64 to sof + 64 + 41 (106)
	-- sender mac = sof + 106 to sof + 106 + 41 (148)
	-- length = sof + 148 to sof + 148 + 15 (164)
	-- data = sof + 164 + length
	-- finally, FCS -> don't need to worry much about this
    

end behav;
