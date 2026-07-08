//
//  OnboardingViewComponents.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

import SwiftUI

enum OnboardingViewComponents {
    
    // MARK: ActionButton
    
    struct ActionButton: View {
        
        let isLastPage: Bool
        let tapAction: EmptyCallback?
        
        var body: some View {
            
            Button {
                tapAction?()
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .frame(minWidth: .zero, maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(.capsule)
            }
        }
    }
    
    // MARK: DismissButton
    
    struct DismissButton: View {
        
        let tapAction: EmptyCallback?
        
        var body: some View {
            Button {
                tapAction?()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.secondarySystemFill))
                    .clipShape(.circle)
            }
        }
    }
    
    // MARK: PageCard
    
    struct PageCard: View {
        
        let page: OnboardingModel.Page
        
        var body: some View {
            VStack(spacing: 40) {
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .lineLimit(1)
                    
                    Text(page.description)
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .lineLimit(3, reservesSpace: true)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
    
    // MARK: PageIndicator
    
    struct PageIndicator: View {
        
        let pages: [OnboardingModel.Page]
        let currentPageIndex: Int
        
        var body: some View {
            HStack(spacing: 8) {
                ForEach(pages) { page in
                    Circle()
                        .fill(page.id == currentPageIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.smooth, value: currentPageIndex)
                }
            }
        }
    }
}
