"
This class implements a set of Character objects that uses a bitmap internally for multibyte characters to quickly tell if they belongs to it or not, rather than using a Dictionary like WideCharacterSet does. Byte characters are tested using a 256-element ByteArray.
"
Class {
	#name : #BitmapCharacterSet,
	#superclass : #Collection,
	#instVars : [
		'byteCharacters',
		'wideCharacters'
	],
	#category : #'Collections-BitmapCharacterSet'
}

{ #category : #'instance creation' }
BitmapCharacterSet class >> new [
	^ self new: 256
]

{ #category : #'instance creation' }
BitmapCharacterSet class >> new: aCapacity [
	^ self basicNew initialize: aCapacity
]

{ #category : #'instance creation' }
BitmapCharacterSet class >> newFrom: aCollection [
	^ self new
		addAll: aCollection;
		yourself	
]

{ #category : #comparing }
BitmapCharacterSet >> = anObject [
	^ self == anObject
		or: [self class == anObject class
			and: [byteCharacters = anObject byteCharacters
				and: [wideCharacters = anObject wideCharacters]]].
]

{ #category : #adding }
BitmapCharacterSet >> add: aCharacter [
	| asciiValue |

	(asciiValue := aCharacter asciiValue) > 255
		ifTrue: [| byteIndex |
			byteIndex := (asciiValue / 8) asInteger + 1.
			(wideCharacters isNil or: [byteIndex > wideCharacters size])
				ifTrue: [self growWideCharacterBitmapTo: (byteIndex * 1.5) asInteger].
			wideCharacters
				at: byteIndex
				put:
					((wideCharacters at: byteIndex)
						bitOr: (16r80 bitShift: (asciiValue \\ 8) negated))]
		ifFalse: [byteCharacters at: asciiValue + 1 put: 1].
	^ aCharacter.
]

{ #category : #private }
BitmapCharacterSet >> byteCharacters [
	^ byteCharacters
]

{ #category : #accessing }
BitmapCharacterSet >> capacity [
	^ byteCharacters size +
		(wideCharacters
			ifNil: [0]
			ifNotNil: [(wideCharacters size) * 8 - 256]).
]

{ #category : #enumerating }
BitmapCharacterSet >> do: aBlock [
	byteCharacters doWithIndex: [:each :i |
		each = 1
			ifTrue: [aBlock value: (Character value: i - 1)]].

	wideCharacters ifNil: [^ self].
	wideCharacters doWithIndex: [:each :byteIndex |
		0 to: 7 do: [:shiftIndex |
			(each bitAnd: (16r80 bitShift: shiftIndex negated)) > 0
				ifTrue: [aBlock value: (Character value: (byteIndex - 1) * 8 + shiftIndex)]]]
]

{ #category : #private }
BitmapCharacterSet >> growWideCharacterBitmapTo: aSize [
	wideCharacters
		ifNil: [
			wideCharacters := ByteArray new: aSize.
			^ self].

	wideCharacters :=
		(ByteArray new: aSize)
			replaceFrom: 1
			to: wideCharacters size
			with: wideCharacters
			startingAt: 1.
]

{ #category : #testing }
BitmapCharacterSet >> hash [
	| hash |

	hash := byteCharacters hash.
	wideCharacters
		ifNotNil: [hash := hash bitXor: wideCharacters hash].
	^ hash.
]

{ #category : #testing }
BitmapCharacterSet >> includes: aCharacter [
	| asciiValue |

	^ (asciiValue := aCharacter asciiValue) > 255
		ifTrue: [ | byteIndex |
			byteIndex := (asciiValue / 8) asInteger + 1.
			(wideCharacters isNil or: [byteIndex > wideCharacters size])
				ifTrue: [^ false].
			^ ((wideCharacters at: byteIndex)
				bitAnd: (16r80 bitShift: (asciiValue \\ 8) negated)) > 0]
		ifFalse: [(byteCharacters at: asciiValue + 1) = 1]
]

{ #category : #initialization }
BitmapCharacterSet >> initialize: aCapacity [
	byteCharacters := ByteArray new: 256.
	aCapacity > 256
		ifTrue: [self growWideCharacterBitmapTo: ((aCapacity - 1) / 8) asInteger + 1].
]

{ #category : #copying }
BitmapCharacterSet >> postCopy [
	byteCharacters := byteCharacters copy.
	wideCharacters
		ifNotNil: [wideCharacters := wideCharacters copy].
]

{ #category : #removing }
BitmapCharacterSet >> remove: aCharacter ifAbsent: aBlock [
	| asciiValue |

	(asciiValue := aCharacter asciiValue) > 255
		ifTrue: [| byteIndex byte bitmask |
			byteIndex := (asciiValue / 8) asInteger + 1.
			(wideCharacters isNil or: [byteIndex > wideCharacters size])
				ifTrue: [^ aBlock value].
			bitmask := 16r80 bitShift: (asciiValue \\ 8) negated.
			((byte := wideCharacters at: byteIndex) bitAnd: bitmask) > 0
				ifFalse: [^ aBlock value].
			wideCharacters at: byteIndex put: (byte bitAnd: bitmask bitInvert)]
		ifFalse: [
			(byteCharacters at: asciiValue + 1) = 1
				ifFalse: [^ aBlock value].
			byteCharacters at: asciiValue + 1 put: 0].
	^ aCharacter.
]

{ #category : #private }
BitmapCharacterSet >> wideCharacters [
	^ wideCharacters
]