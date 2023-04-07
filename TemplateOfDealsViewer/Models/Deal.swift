//
//  Deal.swift
//  TemplateOfDealsViewer
//
//  Created by Анатолий Миронов on 04.04.2023.
//

import Foundation

struct Deal {
  let id: Int64
  let dateModifier: Date
  let instrumentName: String
  let price: Double
  let amount: Double
  let side: Side
  
  enum Side: CaseIterable, Comparable {
    case sell, buy
  }
}
