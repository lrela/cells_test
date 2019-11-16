
// Project: cells 
// Created: 2016-09-28

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle( "cells" )
SetWindowSize( 640, 480, 0 )

// set display properties
//SetVirtualResolution( 1024, 768 )
SetOrientationAllowed( 1, 1, 1, 1 )
SetVirtualResolution ( 640, 480 )


SetSyncRate( 30, 0 ) // 30fps instead of 60 to save battery

#constant ALIVE 1
#constant DEAD 0

type World
	width as integer
	height as integer
	data as integer[]
endtype

type GenerationResult
	modifiedcount as integer
	alivecount as integer
endtype
	

function InitWorld(w ref as World, alivepct as integer)
	w.data.length = w.height * w.width
	
	for y = 0 to w.height-1
		for x = 0 to w.width-1
			if alivepct > 0 and Random2(0, 100) < alivepct
				SetCell(w, x, y, ALIVE)
			else
				SetCell(w, x, y, DEAD)
			endif
		next
	next
endfunction 

function PrintWorld(w ref as World)
	for y = 0 to w.height-1
		for x = 0 to w.width-1
			if GetCell(w, x, y) = ALIVE then printc("o") else printc("_")
		next
		print("")
	next	
endfunction

function AliveNeighbourCount(w ref as World, x as integer, y as integer, max as integer)
	alivecount = 0
	for ny = -1 to 1
		for nx = -1 to 1
			if nx = 0 and ny = 0
				// nothing
			elseif GetNeighbourCell(w, x, y, nx, ny) = ALIVE
				Inc alivecount, 1
				if alivecount = max then exitfunction alivecount
			endif
		next
	next
endfunction alivecount

function GetCell(w ref as World, x as integer, y as integer)
	cell = w.data[x+y*w.width]
endfunction cell

function SetCell(w ref as World, x as integer, y as integer, val as integer)
	w.data[x+y*w.width] = val
endfunction

function TranslateCoord(position as integer, totlength as integer)
	if position >= totlength then exitfunction position - totlength
	if position < 0 then exitfunction totlength - position
endfunction position

/*
 -1,-1   0,-1    1,-1
 -1, 0   0, 0    1, 0
 -1, 1   0, 1    1, 1
*/
function GetNeighbourCell(w ref as World, x as integer, y as integer, xdiff as integer, ydiff as integer)
	nx = x + xdiff
	ny = y + ydiff
	
	if nx = -1 
		nx = w.width - 1
	elseif nx = w.width
		nx = 0
	endif
	
	if ny = -1
		ny = w.height - 1
	elseif ny = w.height
		ny = 0
	endif
		
	cell = GetCell(w, nx, ny)
		
endfunction cell

/*
					Any live cell with fewer than two live neighbours dies, as if caused by under-population.
stayAliveMin|Max: 	Any live cell with two or three live neighbours lives on to the next generation.
					Any live cell with more than three live neighbours dies, as if by over-population.
becomeAlive:		Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

*/
function ProcessGeneration(w ref as World, tmp ref as World, 
	stayAliveMin as integer, stayAliveMax as integer, becomeAlive as integer) 
	
	res as GenerationResult	
	res.modifiedcount = 0
	res.alivecount = 0

	for y = 0 to w.height-1
		for x = 0 to w.width-1
			cell = GetCell(w, x, y)
			ncount = AliveNeighbourCount(w, x, y, 8)

			// handle alive cell
			if cell = ALIVE
				if ncount >= stayAliveMin and ncount <= stayAliveMax
					SetCell(tmp, x, y, ALIVE)
					Inc res.alivecount
				else 
					SetCell(tmp, x, y, DEAD)
					Inc res.modifiedcount
				endif
			else // handle dead
				if ncount = becomeAlive
					SetCell(tmp, x, y, ALIVE)
					Inc res.modifiedcount
					Inc res.alivecount
				else
					SetCell(tmp, x, y, DEAD)
				endif
			endif				
		next
	next
	
	if res.modifiedcount > 0 then w.data = tmp.data
	
endfunction res

function CalcRollingAvg(currentAvg as integer, newVal as integer, valNum as integer)
	avg = currentAvg
	Dec avg, currentAvg / valNum
	Inc avg, newVal / valNum
endfunction avg

function Mutate(w ref as World, xPos as integer, Ypos as integer, width as integer, height as integer, 
	mutationProbPct as integer, cellValue as integer)
	for y = yPos to (yPos + height)
		for x = xPos to (xPos + width)
			if Random2(0, 100) < mutationProbPct
				SetCell(w, TranslateCoord(x, w.width), TranslateCoord(y, w.height), cellValue)
			endif
		next
	next
endfunction


// variables
initalivepct = 30
width = 40
height = 30
aliveRollingAvg = 0
mutationSize = (width+height)/2/5

// setup world
w as World
w.width = width
w.height = height

tmp as World
tmp.width = w.width
tmp.height = w.height

InitWorld(w, initalivepct)
InitWorld(tmp, 0)

res as GenerationResult
generation = 0

cellSprRad = 15

// init gfx
cellImg = LoadImage("cell1.png")
cellSprNum = w.height*w.width+1
cellSprIdx = 1
for y = 0 to w.height - 1
	for x = 0 to w.width - 1
		CreateSprite(cellSprIdx, cellImg)
		SetSpriteSize(cellSprIdx, cellSprRad, cellSprRad)
		SetSpriteVisible(cellSprIdx, 1)
		SetSpritePosition(cellSprIdx, x*cellSprRad, y*cellSprRad)
		Inc cellSprIdx 
	next
next



do

	if GetPointerPressed() = 1
		spr = GetSpriteHit(GetPointerX(), GetPointerY())		
		if spr > 0 
			mutX = TranslateCoord(GetSpriteX(spr)/cellSprRad-mutationSize/2, w.width)
			mutY = TranslateCoord(GetSpriteY(spr)/cellSprRad-mutationSize/2, w.height)
			Mutate(w, mutX, mutY, mutationSize, mutationSize, 33, ALIVE)
		endif
	endif


	cellSprIdx = 1
	for y = 0 to w.height-1
		for x = 0 to w.width-1
			if GetCell(w, x, y) = ALIVE then SetSpriteVisible(cellSprIdx, 1) else SetSpriteVisible(cellSprIdx, 0)
			Inc cellSprIdx
		next
	next	



	//print("alive avg="+ Str(aliveRollingAvg))
    //Print( ScreenFPS() )
    Sync()
    sleep(30)
    
        //PrintWorld(w)
    res = ProcessGeneration(w, tmp, 2, 3, 3)
    aliveRollingAvg = CalcRollingAvg(aliveRollingAvg, res.alivecount, 20)
    Inc generation

loop
