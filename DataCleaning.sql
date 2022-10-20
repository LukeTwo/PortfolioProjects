-- Swap column format from DateTime to Date
Select SaleDate
From Portfolio..Housing

ALTER TABLE Housing
ALTER COLUMN SaleDate Date

Select SaleDate
From Portfolio..Housing

-- Fix address NULLS by using matching data in other columns/rows
Select house1.PropertyAddress, house2.PropertyAddress, ISNULL(house1.PropertyAddress, house2.PropertyAddress)
From Housing house1
join Housing house2
on house1.ParcelID = house2.ParcelID
AND house1.[UniqueID ] != house2.[UniqueID ]
where house1.PropertyAddress is null

UPDATE house1
Set PropertyAddress = ISNULL(house1.PropertyAddress, house2.PropertyAddress)
From Housing house1
join Housing house2
on house1.ParcelID = house2.ParcelID
AND house1.[UniqueID ] != house2.[UniqueID ]
where house1.PropertyAddress is null

-- Seperating long address into smaller more specific columns using substring
Select PropertyAddress, substring(PropertyAddress,1, Charindex(',', PropertyAddress)-1) Address1,
substring(PropertyAddress, Charindex(',', PropertyAddress)+1,len(PropertyAddress)) Address2
From Portfolio..Housing

ALTER TABLE Portfolio..Housing
add Address1 nvarchar(255), Address2 nvarchar(255)

UPDATE Portfolio..Housing
SET Address1 =  substring(PropertyAddress,1, Charindex(',', PropertyAddress)-1)

UPDATE Portfolio..Housing
SET Address2 =  substring(PropertyAddress, Charindex(',', PropertyAddress)+1,len(PropertyAddress))

Select PropertyAddress, Address1, Address2
From Portfolio..Housing 

-- Seperating long address into smaller more specific columns using ParseName
ALTER TABLE Portfolio..Housing
add OwnerBuilding nvarchar(255), OwnerCity nvarchar(255), OwnerState nvarchar(255)

UPDATE Portfolio..Housing
SET OwnerBuilding =  PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE Portfolio..Housing
SET OwnerCity =  PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE Portfolio..Housing
SET OwnerState =  PARSENAME(REPLACE(OwnerAddress,',','.'),1)

Select OwnerAddress, OwnerBuilding, OwnerCity, OwnerState
From Portfolio..Housing 

-- Changing values based on other column values to keep format uniform
Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END
From Portfolio..Housing

UPDATE Portfolio..Housing
SET SoldAsVacant =
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END

-- Remove Duplicates by creating a temp table as to not delete any raw data
Drop Table If EXISTS #Temp1Housing
Select top 0 *
Into #Temp1Housing
From Housing

ALTER TABLE #Temp1Housing
ADD row_num integer

INSERT INTO #Temp1Housing
Select *,
ROW_NUMBER() OVER 
(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference 
	ORDER BY UniqueID) 
From  Housing

DELETE
From #Temp1Housing
Where row_num > 1

-- Remove unused columns from temp table to not delete raw data
ALTER TABLE #Temp1Housing
DROP COLUMN PropertyAddress, OwnerAddress, row_num








