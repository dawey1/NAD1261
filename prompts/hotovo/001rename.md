# Zadání: Přejmenování skenů NAD1261

## Cíl

Vytvořit program, který projde složku `c:\NAD1261_008\`, vyhledá příslušné adresáře a přejmenuje v nich skeny do jednotného formátu.

## Vstupní struktura

- Kořenová složka je `c:\NAD1261_008\`.
- V kořeni se nacházejí adresáře ve tvaru `ajXXX`, kde `XXX` je číslo. Za číslem může být uvedeno také jedno písmeno, například `aj033a`.
- V adresářích `ajXXX` se nacházejí podsložky začínající `bXXX`, kde `XXX` je číslo bodu.
- Název podsložky bodu může obsahovat také písmeno, například `b001a`.
- Název bodu může obsahovat rozsah, například `b005-6`.
- Adresář `ajXXX` může také obsahovat podsložky ve tvaru `infXXX`, například `inf001`, `inf002`.
- Podsložky `infXXX` obsahují skeny informací vztahujících se k dané archivní jednotce.
- Ve složkách bodů se nacházejí obrazové soubory, které se mají přejmenovat.

## Pravidla zpracování

1. Program projde všechny odpovídající adresáře `aj...` a jejich podsložky `b...`.
2. Zpracovávají se pouze soubory s příponou `.jpg`. Jiné soubory se nepřejmenovávají.
3. Skeny v každé složce bodu se seřadí abecedně podle celého původního názvu souboru.
4. Po seřazení se skeny přečíslují od `0001`.
5. Původní číslování skenů nemusí být souvislé ani spolehlivé, protože mohlo dojít ke sloučení skenů z více složek.
6. Pokud jsou skeny rozlišeny písmenem za číslem, musí se tato vazba zachovat i po přečíslování.
7. Podsložky s rozsahem, například `b005-6`, se přejmenují na `b005`.
8. Každé přejmenování podsložky se provede před přejmenováním souborů v dané podsložce.
9. Soubory se budou přejmenovávat přímo na místě, nikoli kopírovat do nové složky.
10. Zpracování musí být možné po přerušení znovu spustit a navázat bez opakování již dokončených změn.
11. Podsložky `infXXX` se zpracují podle samostatných pravidel uvedených níže.

### Přejmenování skenů ve složkách `inf...`

Skeny v podsložkách `infXXX` se přejmenují do formátu:

```text
NAD1261_008_[číslo aj]_inf_[číslo informace]_[číslo skenu].jpg
```

Význam jednotlivých částí:

- `NAD1261_008` je pevný prefix.
- `[číslo aj]` je číslo archivní jednotky z nadřazené složky `aj...`, vždy na tři cifry, případně s písmenem.
- `inf` je pevné označení typu záznamu.
- `[číslo informace]` je číslo z podsložky `infXXX`, vždy na dvě cifry, například `01`.
- `[číslo skenu]` je číslo skenu, vždy na čtyři cifry, případně s písmenem.
- Přípona souboru je `.jpg`.

Příklad:

```text
NAD1261_008_001_inf_01_0603.jpg
```

Tento název označuje archivní jednotku `001`, informaci `01` a sken `0603`. Soubory ve složce `inf...` se stejně jako ostatní skeny nejprve seřadí abecedně podle celého původního názvu. Pokud mají stejné původní číslo a liší se pouze písmenem, zachovají společné nové číslo a písmeno, například `0603.jpg` a `0603a.jpg`.

## Režimy spuštění

Program musí podporovat dva režimy:

### Kontrolní režim

- Program pouze proskenuje kořenovou složku, adresáře `aj...`, podsložky `b...` a soubory.
- V tomto režimu se nesmí přejmenovat žádný adresář ani soubor.
- Program vypíše seznam nalezených problémů a uloží ho do logu.
- Kontrola ověří zejména neodpovídající názvy, nepodporované soubory, kolize cílových názvů, nedostupné položky a chyby ve struktuře adresářů.
- Program může zároveň zobrazit plánované změny, ale pouze informativně.

### Režim přejmenování

- Program provede přímé přejmenování podle pravidel v tomto zadání.
- Tento režim se spustí až po samostatném požadavku uživatele.
- Před přejmenováním se doporučuje nejprve spustit kontrolní režim a ověřit, že nebyly nalezeny problémy.

### Režim vytvoření testovací struktury

- Program projde zdrojovou složku podle stejných pravidel jako v režimu přejmenování.
- Vedle zdrojové složky vytvoří novou cílovou složku. Název cílové složky musí být možné zadat při spuštění nebo nastavit parametrem.
- V cílové složce vytvoří výslednou adresářovou strukturu včetně normalizovaných názvů podsložek, například `b005-6` se vytvoří jako `b005`.
- Do cílové struktury vytvoří `.jpg` soubory s finálními názvy, ale všechny tyto soubory budou mít nulovou velikost. Obsah zdrojových skenů se nekopíruje.
- Zdrojová složka, zdrojové podsložky ani zdrojové soubory se v tomto režimu nesmí změnit.
- Režim musí používat stejné logování jako ostrý režim: `rename_changes.log`, `ignored_files.log` a `rename_state.log`.
- `rename_changes.log` v tomto režimu zaznamená vytvoření každé cílové podsložky a prázdného `.jpg` souboru, včetně zdrojové a cílové cesty.
- `ignored_files.log` zaznamená všechny nepodporované nebo neodpovídající zdrojové soubory včetně důvodu jejich vynechání.
- `rename_state.log` se aktualizuje průběžně po každém úspěšném vytvoření položky a umožní po přerušení pokračovat bez opakování dokončených kroků.
- Režim musí kontrolovat kolize cílových názvů a všechny problémy zapisovat do logů stejně jako ostrý režim.

### Zachování variant skenu

Soubory se stejným původním číslem skenu, které se liší pouze písmenem, tvoří jednu číslovací skupinu.

Například:

```text
NAD1261_0_11_Ka024_aj033a_b001-fol002.jpg
NAD1261_0_11_Ka024_aj033a_b001-fol002a.jpg
```

Původní čísla jsou `002` a `002a`. Po přečíslování musí obě varianty dostat stejné nové základní číslo, například:

```text
..._0001.jpg
..._0001a.jpg
```

Písmeno tedy nesmí způsobit samostatné zvýšení pořadového čísla. Pokud existují další varianty, například `002b`, mají zůstat součástí stejné skupiny a zachovat své písmeno.

## Výstupní formát názvu

Každý sken se přejmenuje do formátu:

```text
NAD1261_008_[číslo aj]_[číslo bodu]_[číslo skenu].jpg
```

Jednotlivé části názvu:

- `NAD1261_008` je pevný prefix.
- `[číslo aj]` je číslo z nadřazené složky `aj...`, vždy na tři cifry, případně s písmenem, například `033` nebo `033a`.
- `[číslo bodu]` je číslo z normalizovaného názvu složky `b...`, vždy na dvě cifry, případně s písmenem. U rozsahové složky `b005-6` se použije pouze první část a výsledný adresář bude `b005`, takže výstupní část názvu bude `05`.
- `[číslo skenu]` je nové pořadové číslo skenu, vždy na čtyři cifry, případně s písmenem, například `0001` nebo `0001a`.
- Přípona souboru je `.jpg`.

## Příklad výsledného názvu

Pro sken ve složce `aj033a` a podsložce `b001`, který je první číslovací skupinou, vznikne například:

```text
NAD1261_008_033a_01_0001.jpg
```

Varianta stejného skenu s písmenem bude například:

```text
NAD1261_008_033a_01_0001a.jpg
```

## Logování a pokračování po přerušení

Program vytvoří samostatné logovací soubory:

- `rename_changes.log` bude obsahovat všechny provedené změny, včetně původního a nového názvu každé podsložky a každého přejmenovaného `.jpg` souboru.
- `ignored_files.log` bude obsahovat všechny nalezené soubory, které nejsou typu `.jpg` nebo jejichž název neodpovídá očekávanému vzoru. Tyto soubory se nepřejmenovávají a u každého se zaznamená důvod vynechání.
- `rename_state.log` bude sloužit jako průběžný stavový log pro pokračování po přerušení.

Každý neúspěšný krok se musí zalogovat. To zahrnuje zejména chyby při procházení adresářů, čtení souborů, rozpoznání názvu, přejmenování podsložky nebo souboru, kolize cílového názvu a chyby při zápisu logu nebo stavového logu. Záznam chyby musí obsahovat čas, typ operace, úplnou cestu k dotčené položce a srozumitelný popis chyby.

`rename_state.log` musí být aktualizován bezprostředně po každém úspěšném přejmenování. Musí z něj být možné zjistit alespoň:

- aktuálně zpracovávaný adresář `aj...`,
- aktuálně zpracovávanou podsložku `b...`,
- poslední úspěšně přejmenovaný soubor,
- čas poslední úspěšné změny,
- případnou chybu, při které bylo zpracování přerušeno.

Při opětovném spuštění program načte stavový log a ověří skutečný stav souborů i složek. Již dokončené změny přeskočí a pokračuje od první nedokončené změny. Pokračování nesmí být založeno pouze na pořadí řádků v logu; program musí kontrolovat, zda původní položka již neexistuje a cílová položka existuje.

Logy mají obsahovat také informaci o chybách a kolizích, ke kterým během zpracování došlo. Po dokončení všech změn se do stavového logu zapíše stav `COMPLETED`.

## Bezpečnost a kontrola

- Program nesmí přepsat existující soubor bez předchozí kontroly a jednoznačného řešení kolize.
- Program provádí přímé přejmenování pouze v režimu přejmenování a před každou změnou musí kontrolovat kolizi cílového názvu.
- Kontrolní režim nesmí provést žádnou změnu v souborovém systému.
- Režim vytvoření testovací struktury nesmí měnit zdrojovou složku a nesmí kopírovat obsah skenů.
- Před vytvořením cílové struktury musí program ověřit, zda cílová složka již existuje, a zabránit nechtěnému přepsání jejích souborů.
- Logy testovacího režimu musí obsahovat stejné informace o úspěšných operacích, chybách, kolizích a přerušení jako logy ostrého režimu.
- Při chybějícím, nečitelném nebo neodpovídajícím názvu souboru se soubor nesmí tiše ztratit; program má chybu zaznamenat.
- Po dokončení má program vypsat nebo uložit přehled provedených změn a chyb.

Názvy souborů, které neodpovídají očekávanému vzoru, se pouze zapíšou do `ignored_files.log` včetně důvodu a soubory zůstanou beze změny.
